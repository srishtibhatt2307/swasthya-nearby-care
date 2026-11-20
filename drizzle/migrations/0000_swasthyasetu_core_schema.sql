
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;

-- ROLES
CREATE TYPE public.app_role AS ENUM ('patient', 'provider', 'admin');
CREATE TYPE public.facility_type AS ENUM ('hospital', 'chc', 'phc', 'clinic');
CREATE TYPE public.ownership_type AS ENUM ('government', 'private');
CREATE TYPE public.appointment_status AS ENUM ('booked', 'completed', 'cancelled', 'no_show');

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END $$;

-- PROFILES
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL DEFAULT '' CHECK (length(full_name) <= 100),
  mobile text UNIQUE CHECK (mobile IS NULL OR mobile ~ '^[6-9][0-9]{9}$'),
  age integer CHECK (age IS NULL OR (age >= 0 AND age <= 120)),
  location text NOT NULL DEFAULT '' CHECK (length(location) <= 120),
  preferred_language text NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en', 'hi', 'hne')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL,
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

-- New user -> profile + patient role
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_mobile text := nullif(btrim(coalesce(NEW.raw_user_meta_data ->> 'mobile', '')), '');
  v_age_text text := nullif(btrim(coalesce(NEW.raw_user_meta_data ->> 'age', '')), '');
  v_age integer;
BEGIN
  IF v_mobile IS NOT NULL AND v_mobile !~ '^[6-9][0-9]{9}$' THEN v_mobile := NULL; END IF;
  IF v_age_text ~ '^[0-9]{1,3}$' THEN
    v_age := v_age_text::integer;
    IF v_age > 120 THEN v_age := NULL; END IF;
  END IF;
  INSERT INTO public.profiles (id, full_name, mobile, age, location)
  VALUES (
    NEW.id,
    left(btrim(coalesce(NEW.raw_user_meta_data ->> 'full_name', '')), 100),
    v_mobile,
    v_age,
    left(btrim(coalesce(NEW.raw_user_meta_data ->> 'location', '')), 120)
  );
  INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'patient') ON CONFLICT DO NOTHING;
  RETURN NEW;
END $$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- HOSPITALS
CREATE TABLE public.hospitals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(name) BETWEEN 2 AND 150),
  facility_type public.facility_type NOT NULL,
  ownership public.ownership_type NOT NULL,
  address text NOT NULL DEFAULT '',
  town text NOT NULL DEFAULT '',
  district text NOT NULL DEFAULT '',
  state text NOT NULL DEFAULT 'Chhattisgarh',
  pincode text NOT NULL DEFAULT '',
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  phone text NOT NULL DEFAULT '',
  emergency_phone text NOT NULL DEFAULT '',
  facilities text[] NOT NULL DEFAULT '{}',
  open_24x7 boolean NOT NULL DEFAULT false,
  open_time time NOT NULL DEFAULT '09:00',
  close_time time NOT NULL DEFAULT '17:00',
  open_days smallint[] NOT NULL DEFAULT '{1,2,3,4,5,6}',
  beds integer,
  description text NOT NULL DEFAULT '',
  is_demo boolean NOT NULL DEFAULT true,
  is_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.hospitals TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.hospitals TO authenticated;
GRANT ALL ON public.hospitals TO service_role;
ALTER TABLE public.hospitals ENABLE ROW LEVEL SECURITY;
CREATE TRIGGER hospitals_updated_at BEFORE UPDATE ON public.hospitals FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.hospital_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hospital_id uuid NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
  user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (hospital_id, user_id)
);
GRANT SELECT ON public.hospital_staff TO authenticated;
GRANT ALL ON public.hospital_staff TO service_role;
ALTER TABLE public.hospital_staff ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff view own links" ON public.hospital_staff FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.has_role(auth.uid(), 'admin'));

CREATE OR REPLACE FUNCTION public.is_hospital_staff(_user_id uuid, _hospital_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.hospital_staff WHERE user_id = _user_id AND hospital_id = _hospital_id)
     OR public.has_role(_user_id, 'admin')
$$;

CREATE POLICY "Anyone can view hospitals" ON public.hospitals FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Staff update their hospital" ON public.hospitals FOR UPDATE TO authenticated
  USING (public.is_hospital_staff(auth.uid(), id)) WITH CHECK (public.is_hospital_staff(auth.uid(), id));
CREATE POLICY "Admins insert hospitals" ON public.hospitals FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins delete hospitals" ON public.hospitals FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'admin'));

-- Staff cannot change sample/verified flags
CREATE OR REPLACE FUNCTION public.protect_hospital_flags()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND NOT public.has_role(auth.uid(), 'admin') THEN
    NEW.is_demo := OLD.is_demo;
    NEW.is_verified := OLD.is_verified;
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER hospitals_protect_flags BEFORE UPDATE ON public.hospitals FOR EACH ROW EXECUTE FUNCTION public.protect_hospital_flags();

-- DOCTORS
CREATE TABLE public.doctors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hospital_id uuid NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
  full_name text NOT NULL CHECK (length(full_name) BETWEEN 2 AND 100),
  gender text NOT NULL DEFAULT 'female' CHECK (gender IN ('female', 'male', 'other')),
  specialization text NOT NULL,
  qualification text NOT NULL DEFAULT '',
  experience_years integer NOT NULL DEFAULT 0 CHECK (experience_years BETWEEN 0 AND 70),
  languages text[] NOT NULL DEFAULT '{Hindi}',
  fee integer NOT NULL DEFAULT 0 CHECK (fee BETWEEN 0 AND 100000),
  photo_url text,
  bio text NOT NULL DEFAULT '',
  consultation_days smallint[] NOT NULL DEFAULT '{1,2,3,4,5,6}',
  start_time time NOT NULL DEFAULT '10:00',
  end_time time NOT NULL DEFAULT '14:00',
  slot_minutes integer NOT NULL DEFAULT 15 CHECK (slot_minutes BETWEEN 5 AND 120),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT doctor_hours_valid CHECK (end_time > start_time)
);
CREATE INDEX doctors_hospital_idx ON public.doctors(hospital_id);
GRANT SELECT ON public.doctors TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.doctors TO authenticated;
GRANT ALL ON public.doctors TO service_role;
ALTER TABLE public.doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active doctors" ON public.doctors FOR SELECT TO anon, authenticated
  USING (is_active OR public.is_hospital_staff(auth.uid(), hospital_id));
CREATE POLICY "Staff add doctors" ON public.doctors FOR INSERT TO authenticated WITH CHECK (public.is_hospital_staff(auth.uid(), hospital_id));
CREATE POLICY "Staff update doctors" ON public.doctors FOR UPDATE TO authenticated
  USING (public.is_hospital_staff(auth.uid(), hospital_id)) WITH CHECK (public.is_hospital_staff(auth.uid(), hospital_id));
CREATE POLICY "Staff delete doctors" ON public.doctors FOR DELETE TO authenticated USING (public.is_hospital_staff(auth.uid(), hospital_id));
CREATE TRIGGER doctors_updated_at BEFORE UPDATE ON public.doctors FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- DOCTOR TIME OFF
CREATE TABLE public.doctor_time_off (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id uuid NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  reason text NOT NULL DEFAULT '' CHECK (length(reason) <= 200),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT time_off_valid CHECK (ends_at > starts_at)
);
CREATE INDEX time_off_doctor_idx ON public.doctor_time_off(doctor_id);
GRANT SELECT, INSERT, DELETE ON public.doctor_time_off TO authenticated;
GRANT ALL ON public.doctor_time_off TO service_role;
ALTER TABLE public.doctor_time_off ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Staff view time off" ON public.doctor_time_off FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.doctors d WHERE d.id = doctor_id AND public.is_hospital_staff(auth.uid(), d.hospital_id)));
CREATE POLICY "Staff add time off" ON public.doctor_time_off FOR INSERT TO authenticated
  WITH CHECK (EXISTS (SELECT 1 FROM public.doctors d WHERE d.id = doctor_id AND public.is_hospital_staff(auth.uid(), d.hospital_id)));
CREATE POLICY "Staff remove time off" ON public.doctor_time_off FOR DELETE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.doctors d WHERE d.id = doctor_id AND public.is_hospital_staff(auth.uid(), d.hospital_id)));

-- APPOINTMENTS
CREATE TABLE public.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  patient_id uuid,
  booked_by uuid NOT NULL,
  doctor_id uuid NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  hospital_id uuid NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  status public.appointment_status NOT NULL DEFAULT 'booked',
  patient_name text NOT NULL,
  patient_age integer NOT NULL CHECK (patient_age BETWEEN 0 AND 120),
  patient_mobile text NOT NULL CHECK (patient_mobile ~ '^[6-9][0-9]{9}$'),
  reason text NOT NULL DEFAULT '',
  is_walk_in boolean NOT NULL DEFAULT false,
  cancel_reason text NOT NULL DEFAULT '',
  reschedule_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT appointment_positive_duration CHECK (ends_at > starts_at),
  CONSTRAINT appointment_no_overlap EXCLUDE USING gist (
    doctor_id WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
  ) WHERE (status = 'booked')
);
CREATE INDEX appointments_patient_idx ON public.appointments(patient_id);
CREATE INDEX appointments_hospital_idx ON public.appointments(hospital_id, starts_at);
GRANT SELECT ON public.appointments TO authenticated;
GRANT ALL ON public.appointments TO service_role;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Patients and staff view appointments" ON public.appointments FOR SELECT TO authenticated
  USING (auth.uid() = patient_id OR public.is_hospital_staff(auth.uid(), hospital_id));
CREATE TRIGGER appointments_updated_at BEFORE UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- SAVED
CREATE TABLE public.saved_hospitals (
  user_id uuid NOT NULL,
  hospital_id uuid NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, hospital_id)
);
GRANT SELECT, INSERT, DELETE ON public.saved_hospitals TO authenticated;
GRANT ALL ON public.saved_hospitals TO service_role;
ALTER TABLE public.saved_hospitals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own saved hospitals select" ON public.saved_hospitals FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Own saved hospitals insert" ON public.saved_hospitals FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Own saved hospitals delete" ON public.saved_hospitals FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE public.saved_doctors (
  user_id uuid NOT NULL,
  doctor_id uuid NOT NULL REFERENCES public.doctors(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, doctor_id)
);
GRANT SELECT, INSERT, DELETE ON public.saved_doctors TO authenticated;
GRANT ALL ON public.saved_doctors TO service_role;
ALTER TABLE public.saved_doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own saved doctors select" ON public.saved_doctors FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Own saved doctors insert" ON public.saved_doctors FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Own saved doctors delete" ON public.saved_doctors FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- NOTIFICATIONS
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  kind text NOT NULL,
  appointment_id uuid REFERENCES public.appointments(id) ON DELETE CASCADE,
  payload jsonb NOT NULL DEFAULT '{}',
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifications_user_idx ON public.notifications(user_id, created_at DESC);
GRANT SELECT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO service_role;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own notifications select" ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Own notifications update" ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Own notifications delete" ON public.notifications FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.notify_appointment_change()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_kind text;
  v_payload jsonb;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_kind := 'booked';
  ELSIF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
    v_kind := 'cancelled';
  ELSIF NEW.starts_at <> OLD.starts_at THEN
    v_kind := 'rescheduled';
  ELSIF NEW.status = 'completed' AND OLD.status <> 'completed' THEN
    v_kind := 'completed';
  ELSE
    RETURN NEW;
  END IF;

  SELECT jsonb_build_object(
    'code', NEW.code,
    'starts_at', NEW.starts_at,
    'doctor_name', d.full_name,
    'hospital_name', h.name,
    'patient_name', NEW.patient_name
  ) INTO v_payload
  FROM public.doctors d JOIN public.hospitals h ON h.id = d.hospital_id
  WHERE d.id = NEW.doctor_id;

  IF NEW.patient_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, kind, appointment_id, payload)
    VALUES (NEW.patient_id, v_kind, NEW.id, coalesce(v_payload, '{}'));
  END IF;

  INSERT INTO public.notifications (user_id, kind, appointment_id, payload)
  SELECT s.user_id, 'staff_' || v_kind, NEW.id, coalesce(v_payload, '{}')
  FROM public.hospital_staff s
  WHERE s.hospital_id = NEW.hospital_id AND s.user_id IS DISTINCT FROM NEW.patient_id;

  RETURN NEW;
END $$;
CREATE TRIGGER appointments_notify AFTER INSERT OR UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.notify_appointment_change();

-- SLOTS (business time zone: Asia/Kolkata)
CREATE OR REPLACE FUNCTION public.get_available_slots(_doctor_id uuid, _date date)
RETURNS TABLE (slot_start timestamptz, slot_end timestamptz, is_available boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_doc public.doctors%ROWTYPE;
  v_today date := (now() AT TIME ZONE 'Asia/Kolkata')::date;
  v_step interval;
BEGIN
  SELECT * INTO v_doc FROM public.doctors WHERE id = _doctor_id AND is_active;
  IF NOT FOUND THEN RETURN; END IF;
  IF _date < v_today OR _date > v_today + 30 THEN RETURN; END IF;
  IF NOT (extract(dow FROM _date)::smallint = ANY (v_doc.consultation_days)) THEN RETURN; END IF;
  v_step := make_interval(mins => v_doc.slot_minutes);

  RETURN QUERY
  SELECT g.st, g.st + v_step,
    (g.st > now() + interval '15 minutes'
      AND NOT EXISTS (
        SELECT 1 FROM public.appointments a
        WHERE a.doctor_id = _doctor_id AND a.status = 'booked'
          AND tstzrange(a.starts_at, a.ends_at, '[)') && tstzrange(g.st, g.st + v_step, '[)'))
      AND NOT EXISTS (
        SELECT 1 FROM public.doctor_time_off o
        WHERE o.doctor_id = _doctor_id
          AND tstzrange(o.starts_at, o.ends_at, '[)') && tstzrange(g.st, g.st + v_step, '[)')))
  FROM generate_series(
    (_date + v_doc.start_time) AT TIME ZONE 'Asia/Kolkata',
    ((_date + v_doc.end_time) AT TIME ZONE 'Asia/Kolkata') - v_step,
    v_step
  ) AS g(st)
  ORDER BY g.st;
END $$;

CREATE OR REPLACE FUNCTION public.slot_is_open(_doctor_id uuid, _slot_start timestamptz)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.get_available_slots(_doctor_id, (_slot_start AT TIME ZONE 'Asia/Kolkata')::date) s
    WHERE s.slot_start = _slot_start AND s.is_available
  )
$$;

CREATE OR REPLACE FUNCTION public.book_appointment(
  _doctor_id uuid,
  _slot_start timestamptz,
  _patient_name text,
  _patient_age integer,
  _patient_mobile text,
  _reason text DEFAULT '',
  _walk_in boolean DEFAULT false
)
RETURNS TABLE (appointment_id uuid, appointment_code text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_doc public.doctors%ROWTYPE;
  v_code text;
  v_id uuid;
  v_name text := btrim(coalesce(_patient_name, ''));
  v_mobile text := btrim(coalesce(_patient_mobile, ''));
  v_reason text := btrim(coalesce(_reason, ''));
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'SIGN_IN_REQUIRED'; END IF;
  SELECT * INTO v_doc FROM public.doctors WHERE id = _doctor_id AND is_active;
  IF NOT FOUND THEN RAISE EXCEPTION 'DOCTOR_UNAVAILABLE'; END IF;
  IF length(v_name) < 2 OR length(v_name) > 100 THEN RAISE EXCEPTION 'INVALID_NAME'; END IF;
  IF _patient_age IS NULL OR _patient_age < 0 OR _patient_age > 120 THEN RAISE EXCEPTION 'INVALID_AGE'; END IF;
  IF v_mobile !~ '^[6-9][0-9]{9}$' THEN RAISE EXCEPTION 'INVALID_MOBILE'; END IF;
  IF length(v_reason) > 500 THEN RAISE EXCEPTION 'INVALID_REASON'; END IF;
  IF _walk_in AND NOT public.is_hospital_staff(v_uid, v_doc.hospital_id) THEN RAISE EXCEPTION 'NOT_ALLOWED'; END IF;
  IF NOT public.slot_is_open(_doctor_id, _slot_start) THEN RAISE EXCEPTION 'SLOT_TAKEN'; END IF;

  LOOP
    v_code := 'SS-' || upper(substr(md5(gen_random_uuid()::text), 1, 6));
    EXIT WHEN NOT EXISTS (SELECT 1 FROM public.appointments WHERE code = v_code);
  END LOOP;

  BEGIN
    INSERT INTO public.appointments (code, patient_id, booked_by, doctor_id, hospital_id, starts_at, ends_at,
      patient_name, patient_age, patient_mobile, reason, is_walk_in)
    VALUES (v_code, CASE WHEN _walk_in THEN NULL ELSE v_uid END, v_uid, _doctor_id, v_doc.hospital_id,
      _slot_start, _slot_start + make_interval(mins => v_doc.slot_minutes),
      v_name, _patient_age, v_mobile, v_reason, _walk_in)
    RETURNING id INTO v_id;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'SLOT_TAKEN';
  END;

  RETURN QUERY SELECT v_id, v_code;
END $$;

CREATE OR REPLACE FUNCTION public.reschedule_appointment(_appointment_id uuid, _new_start timestamptz)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_a public.appointments%ROWTYPE;
  v_doc public.doctors%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'SIGN_IN_REQUIRED'; END IF;
  SELECT * INTO v_a FROM public.appointments WHERE id = _appointment_id;
  IF NOT FOUND OR NOT (v_a.patient_id = v_uid OR public.is_hospital_staff(v_uid, v_a.hospital_id)) THEN
    RAISE EXCEPTION 'NOT_FOUND';
  END IF;
  IF v_a.status <> 'booked' OR v_a.starts_at <= now() THEN RAISE EXCEPTION 'NOT_RESCHEDULABLE'; END IF;
  IF _new_start = v_a.starts_at THEN RAISE EXCEPTION 'SAME_SLOT'; END IF;
  IF NOT public.slot_is_open(v_a.doctor_id, _new_start) THEN RAISE EXCEPTION 'SLOT_TAKEN'; END IF;
  SELECT * INTO v_doc FROM public.doctors WHERE id = v_a.doctor_id;
  BEGIN
    UPDATE public.appointments
      SET starts_at = _new_start,
          ends_at = _new_start + make_interval(mins => v_doc.slot_minutes),
          reschedule_count = reschedule_count + 1
      WHERE id = _appointment_id;
  EXCEPTION WHEN exclusion_violation THEN
    RAISE EXCEPTION 'SLOT_TAKEN';
  END;
END $$;

CREATE OR REPLACE FUNCTION public.cancel_appointment(_appointment_id uuid, _reason text DEFAULT '')
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_a public.appointments%ROWTYPE;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'SIGN_IN_REQUIRED'; END IF;
  SELECT * INTO v_a FROM public.appointments WHERE id = _appointment_id;
  IF NOT FOUND OR NOT (v_a.patient_id = v_uid OR public.is_hospital_staff(v_uid, v_a.hospital_id)) THEN
    RAISE EXCEPTION 'NOT_FOUND';
  END IF;
  IF v_a.status <> 'booked' THEN RAISE EXCEPTION 'NOT_CANCELLABLE'; END IF;
  UPDATE public.appointments
    SET status = 'cancelled', cancel_reason = left(btrim(coalesce(_reason, '')), 300)
    WHERE id = _appointment_id;
END $$;

CREATE OR REPLACE FUNCTION public.set_appointment_status(_appointment_id uuid, _status public.appointment_status)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_a public.appointments%ROWTYPE;
BEGIN
  SELECT * INTO v_a FROM public.appointments WHERE id = _appointment_id;
  IF v_uid IS NULL OR NOT FOUND OR NOT public.is_hospital_staff(v_uid, v_a.hospital_id) THEN
    RAISE EXCEPTION 'NOT_ALLOWED';
  END IF;
  IF _status NOT IN ('completed', 'no_show') OR v_a.status <> 'booked' THEN RAISE EXCEPTION 'INVALID_STATUS'; END IF;
  UPDATE public.appointments SET status = _status WHERE id = _appointment_id;
END $$;

-- Demo: claim a SAMPLE hospital to manage it. Real (non-demo) hospitals need an admin.
CREATE OR REPLACE FUNCTION public.claim_demo_hospital(_hospital_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'SIGN_IN_REQUIRED'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.hospitals WHERE id = _hospital_id AND is_demo) THEN
    RAISE EXCEPTION 'VERIFICATION_REQUIRED';
  END IF;
  INSERT INTO public.hospital_staff (hospital_id, user_id) VALUES (_hospital_id, v_uid) ON CONFLICT DO NOTHING;
  INSERT INTO public.user_roles (user_id, role) VALUES (v_uid, 'provider') ON CONFLICT DO NOTHING;
END $$;

REVOKE EXECUTE ON FUNCTION public.book_appointment(uuid, timestamptz, text, integer, text, text, boolean) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.reschedule_appointment(uuid, timestamptz) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.cancel_appointment(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.set_appointment_status(uuid, public.appointment_status) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.claim_demo_hospital(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.book_appointment(uuid, timestamptz, text, integer, text, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reschedule_appointment(uuid, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cancel_appointment(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_appointment_status(uuid, public.appointment_status) TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_demo_hospital(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_available_slots(uuid, date) TO anon, authenticated;
