export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      appointments: {
        Row: {
          booked_by: string
          cancel_reason: string
          code: string
          created_at: string
          doctor_id: string
          ends_at: string
          hospital_id: string
          id: string
          is_walk_in: boolean
          patient_age: number
          patient_id: string | null
          patient_mobile: string
          patient_name: string
          reason: string
          reschedule_count: number
          starts_at: string
          status: Database["public"]["Enums"]["appointment_status"]
          updated_at: string
        }
        Insert: {
          booked_by: string
          cancel_reason?: string
          code: string
          created_at?: string
          doctor_id: string
          ends_at: string
          hospital_id: string
          id?: string
          is_walk_in?: boolean
          patient_age: number
          patient_id?: string | null
          patient_mobile: string
          patient_name: string
          reason?: string
          reschedule_count?: number
          starts_at: string
          status?: Database["public"]["Enums"]["appointment_status"]
          updated_at?: string
        }
        Update: {
          booked_by?: string
          cancel_reason?: string
          code?: string
          created_at?: string
          doctor_id?: string
          ends_at?: string
          hospital_id?: string
          id?: string
          is_walk_in?: boolean
          patient_age?: number
          patient_id?: string | null
          patient_mobile?: string
          patient_name?: string
          reason?: string
          reschedule_count?: number
          starts_at?: string
          status?: Database["public"]["Enums"]["appointment_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "appointments_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "appointments_hospital_id_fkey"
            columns: ["hospital_id"]
            isOneToOne: false
            referencedRelation: "hospitals"
            referencedColumns: ["id"]
          },
        ]
      }
      doctor_time_off: {
        Row: {
          created_at: string
          doctor_id: string
          ends_at: string
          id: string
          reason: string
          starts_at: string
        }
        Insert: {
          created_at?: string
          doctor_id: string
          ends_at: string
          id?: string
          reason?: string
          starts_at: string
        }
        Update: {
          created_at?: string
          doctor_id?: string
          ends_at?: string
          id?: string
          reason?: string
          starts_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "doctor_time_off_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
        ]
      }
      doctors: {
        Row: {
          bio: string
          consultation_days: number[]
          created_at: string
          end_time: string
          experience_years: number
          fee: number
          full_name: string
          gender: string
          hospital_id: string
          id: string
          is_active: boolean
          languages: string[]
          photo_url: string | null
          qualification: string
          slot_minutes: number
          specialization: string
          start_time: string
          updated_at: string
        }
        Insert: {
          bio?: string
          consultation_days?: number[]
          created_at?: string
          end_time?: string
          experience_years?: number
          fee?: number
          full_name: string
          gender?: string
          hospital_id: string
          id?: string
          is_active?: boolean
          languages?: string[]
          photo_url?: string | null
          qualification?: string
          slot_minutes?: number
          specialization: string
          start_time?: string
          updated_at?: string
        }
        Update: {
          bio?: string
          consultation_days?: number[]
          created_at?: string
          end_time?: string
          experience_years?: number
          fee?: number
          full_name?: string
          gender?: string
          hospital_id?: string
          id?: string
          is_active?: boolean
          languages?: string[]
          photo_url?: string | null
          qualification?: string
          slot_minutes?: number
          specialization?: string
          start_time?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "doctors_hospital_id_fkey"
            columns: ["hospital_id"]
            isOneToOne: false
            referencedRelation: "hospitals"
            referencedColumns: ["id"]
          },
        ]
      }
      hospital_staff: {
        Row: {
          created_at: string
          hospital_id: string
          id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          hospital_id: string
          id?: string
          user_id: string
        }
        Update: {
          created_at?: string
          hospital_id?: string
          id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "hospital_staff_hospital_id_fkey"
            columns: ["hospital_id"]
            isOneToOne: false
            referencedRelation: "hospitals"
            referencedColumns: ["id"]
          },
        ]
      }
      hospitals: {
        Row: {
          address: string
          beds: number | null
          close_time: string
          created_at: string
          description: string
          district: string
          emergency_phone: string
          facilities: string[]
          facility_type: Database["public"]["Enums"]["facility_type"]
          id: string
          is_demo: boolean
          is_verified: boolean
          latitude: number
          longitude: number
          name: string
          open_24x7: boolean
          open_days: number[]
          open_time: string
          ownership: Database["public"]["Enums"]["ownership_type"]
          phone: string
          pincode: string
          state: string
          town: string
          updated_at: string
        }
        Insert: {
          address?: string
          beds?: number | null
          close_time?: string
          created_at?: string
          description?: string
          district?: string
          emergency_phone?: string
          facilities?: string[]
          facility_type: Database["public"]["Enums"]["facility_type"]
          id?: string
          is_demo?: boolean
          is_verified?: boolean
          latitude: number
          longitude: number
          name: string
          open_24x7?: boolean
          open_days?: number[]
          open_time?: string
          ownership: Database["public"]["Enums"]["ownership_type"]
          phone?: string
          pincode?: string
          state?: string
          town?: string
          updated_at?: string
        }
        Update: {
          address?: string
          beds?: number | null
          close_time?: string
          created_at?: string
          description?: string
          district?: string
          emergency_phone?: string
          facilities?: string[]
          facility_type?: Database["public"]["Enums"]["facility_type"]
          id?: string
          is_demo?: boolean
          is_verified?: boolean
          latitude?: number
          longitude?: number
          name?: string
          open_24x7?: boolean
          open_days?: number[]
          open_time?: string
          ownership?: Database["public"]["Enums"]["ownership_type"]
          phone?: string
          pincode?: string
          state?: string
          town?: string
          updated_at?: string
        }
        Relationships: []
      }
      notifications: {
        Row: {
          appointment_id: string | null
          created_at: string
          id: string
          kind: string
          payload: Json
          read_at: string | null
          user_id: string
        }
        Insert: {
          appointment_id?: string | null
          created_at?: string
          id?: string
          kind: string
          payload?: Json
          read_at?: string | null
          user_id: string
        }
        Update: {
          appointment_id?: string | null
          created_at?: string
          id?: string
          kind?: string
          payload?: Json
          read_at?: string | null
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_appointment_id_fkey"
            columns: ["appointment_id"]
            isOneToOne: false
            referencedRelation: "appointments"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          age: number | null
          created_at: string
          full_name: string
          id: string
          location: string
          mobile: string | null
          preferred_language: string
          updated_at: string
        }
        Insert: {
          age?: number | null
          created_at?: string
          full_name?: string
          id: string
          location?: string
          mobile?: string | null
          preferred_language?: string
          updated_at?: string
        }
        Update: {
          age?: number | null
          created_at?: string
          full_name?: string
          id?: string
          location?: string
          mobile?: string | null
          preferred_language?: string
          updated_at?: string
        }
        Relationships: []
      }
      saved_doctors: {
        Row: {
          created_at: string
          doctor_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          doctor_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          doctor_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_doctors_doctor_id_fkey"
            columns: ["doctor_id"]
            isOneToOne: false
            referencedRelation: "doctors"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_hospitals: {
        Row: {
          created_at: string
          hospital_id: string
          user_id: string
        }
        Insert: {
          created_at?: string
          hospital_id: string
          user_id: string
        }
        Update: {
          created_at?: string
          hospital_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "saved_hospitals_hospital_id_fkey"
            columns: ["hospital_id"]
            isOneToOne: false
            referencedRelation: "hospitals"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      book_appointment: {
        Args: {
          _doctor_id: string
          _patient_age: number
          _patient_mobile: string
          _patient_name: string
          _reason?: string
          _slot_start: string
          _walk_in?: boolean
        }
        Returns: {
          appointment_code: string
          appointment_id: string
        }[]
      }
      cancel_appointment: {
        Args: { _appointment_id: string; _reason?: string }
        Returns: undefined
      }
      claim_demo_hospital: {
        Args: { _hospital_id: string }
        Returns: undefined
      }
      get_available_slots: {
        Args: { _date: string; _doctor_id: string }
        Returns: {
          is_available: boolean
          slot_end: string
          slot_start: string
        }[]
      }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_hospital_staff: {
        Args: { _hospital_id: string; _user_id: string }
        Returns: boolean
      }
      reschedule_appointment: {
        Args: { _appointment_id: string; _new_start: string }
        Returns: undefined
      }
      set_appointment_status: {
        Args: {
          _appointment_id: string
          _status: Database["public"]["Enums"]["appointment_status"]
        }
        Returns: undefined
      }
      slot_is_open: {
        Args: { _doctor_id: string; _slot_start: string }
        Returns: boolean
      }
    }
    Enums: {
      app_role: "patient" | "provider" | "admin"
      appointment_status: "booked" | "completed" | "cancelled" | "no_show"
      facility_type: "hospital" | "chc" | "phc" | "clinic"
      ownership_type: "government" | "private"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["patient", "provider", "admin"],
      appointment_status: ["booked", "completed", "cancelled", "no_show"],
      facility_type: ["hospital", "chc", "phc", "clinic"],
      ownership_type: ["government", "private"],
    },
  },
} as const
