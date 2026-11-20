# Swasthya Nearby Care

Build a modern, user-friendly and fully responsive website called **"SwasthyaSetu – Connecting Rural Communities to Healthcare"**.

### About the Project

We are developing this website as a college project to solve a real-life problem faced by people living in rural and remote areas. Many people struggle to find nearby hospitals, know which doctors are available, check hospital facilities, or book appointments without travelling long distances.

I don't want this website to look like a typical hospital website. I want it to work as a healthcare access platform that connects rural patients with nearby hospitals, clinics, Primary Health Centres (PHCs), doctors, and other healthcare services.

The overall experience should feel simple, welcoming, trustworthy, and human. Imagine an elderly person or someone with very little technical knowledge using this website. They should be able to understand where to click and what to do without confusion.

### 1. Homepage and Landing Page

Create an attractive homepage with:

- A welcoming headline such as "Healthcare is closer than you think."
- A short introduction explaining how the platform helps rural communities.
- A prominent search bar where users can search for hospitals, doctors, specialisations, or healthcare services.
- A location search option to find nearby healthcare centres.
- Quick-access buttons for Find a Hospital, Find a Doctor, Book Appointment, and Emergency Help.
- A section showing nearby healthcare centres.
- A section highlighting available doctors.
- A simple explanation of how the platform works.
- A footer containing contact details, FAQs, About Us, and important links.

### 2. Patient Registration and Login

Create a simple registration and login system.

- Register using name, mobile number, age, and location.
- Allow patients to log in securely.
- Keep the registration process short and easy.
- Provide a patient dashboard after login.
- Allow patients to edit their profile and personal details.

### 3. Find Nearby Hospitals and Healthcare Centres

This should be one of the main features.

- Display nearby government hospitals, private hospitals, clinics, and PHCs.
- Show hospital name, address, distance, contact number, available facilities, and operating hours.
- Add an interactive map to help users locate hospitals.
- Include filters such as government/private, distance, emergency services, and available facilities.
- Allow users to view hospital details and directions.

### 4. Find and Search Doctors

Create a separate section for finding doctors.

Display:
- Doctor's name and profile picture.
- Specialisation (General Physician, Dentist, Cardiologist, Gynaecologist, etc.).
- Hospital or clinic where they work.
- Consultation timings.
- Availability status.
- Consultation fee, if applicable.

Allow patients to search doctors by name, specialisation, location, and availability.

### 5. Appointment Booking System

Make the appointment process straightforward.

- Select a hospital or doctor.
- View available appointment dates and time slots.
- Choose a suitable slot.
- Enter basic patient information.
- Confirm the appointment.
- Display a booking confirmation with appointment ID.
- Allow users to view, reschedule, or cancel appointments.

### 6. Emergency Assistance

Create a clearly visible Emergency Help section.

- Display important emergency contact numbers.
- Help users locate nearby hospitals offering emergency services.
- Show directions and hospital contact details.
- Provide a prominent emergency call option.

Make sure this section is easy to find from every major page. Do not pretend that the website itself provides ambulance dispatch or emergency response unless such a service is actually integrated.

### 7. Health Awareness and Information

Add a section dedicated to spreading basic healthcare awareness.

Include:
- Common diseases and their symptoms.
- Preventive healthcare tips.
- Hygiene and sanitation awareness.
- Maternal and child healthcare information.
- Vaccination awareness.
- Seasonal disease prevention.

Keep the language simple and easy to understand.

### 8. Regional Language Support

Since the platform is designed for rural communities, language accessibility is important.

- Add a language selector.
- Initially support English and Hindi.
- Keep the option open for adding regional languages such as Chhattisgarhi.
- Use simple words and avoid complicated medical terminology.
- Add clear icons wherever possible.

### 9. Patient Dashboard

After logging in, patients should be able to:

- View upcoming appointments.
- Check previous bookings.
- Manage their profile.
- Find saved hospitals and doctors.
- Receive appointment reminders and booking updates.
- Access important healthcare information.

### 10. Hospital and Doctor Dashboard

Create a separate login/dashboard for verified healthcare providers.

Hospitals and authorised staff should be able to:

- Manage hospital profiles.
- Add or update doctor details.
- Update consultation timings.
- Manage available appointment slots.
- View upcoming appointments.
- Update available healthcare facilities.

Only authorised users should be able to modify hospital and doctor information.

### 11. User-Friendly Design Requirements

The design is extremely important. I want the website to look professional but not overly complicated.

Follow these design guidelines:

- Use a clean, modern healthcare-inspired interface.
- Use a calming colour palette with shades of teal, green, white, and light blue.
- Use readable fonts and appropriately sized buttons.
- Make navigation simple and consistent.
- Ensure the website works smoothly on mobile phones, tablets, and desktops.
- Use clear icons and illustrations.
- Avoid overcrowded pages and unnecessary animations.
- Make important features accessible within one or two clicks.
- Include loading indicators, success messages, error messages, and empty states.
- Make the website accessible to elderly users and people with limited digital literacy.
- Optimise the website for slow internet connections.

### 12. Technical and Functional Requirements

This should be a working website, not just a collection of attractive static pages.

- Create a proper frontend and backend.
- Use a database to store patient details, hospital information, doctor profiles, and appointments.
- Implement functional search and filtering.
- Implement authentication and role-based access.
- Make appointment booking functional.
- Validate user inputs.
- Display realistic sample data for the college project demonstration.
- Keep the code organised and easy to understand.
- Use secure handling of user information.
- Clearly distinguish sample/demo hospital data from verified real healthcare providers.

### Final Goal

The main goal is to create a platform that makes finding and accessing healthcare services easier for people living in rural areas.

I want the final website to feel like a real-world product that could genuinely help someone living in a remote village.

Prioritise functionality, accessibility, simplicity, and a smooth user experience over unnecessary visual effects.

Before starting, plan the website structure, pages, database, and user flow. Then build the complete project step by step. Make sure all navigation links, buttons, forms, search features, and appointment workflows actually work.

This project was built with [Lovable](https://lovable.dev).

**Live app**: https://swasthya-nearby-care.lovable.app

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/5cc18065-519f-4a41-ba2d-caad0fdf5739).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
