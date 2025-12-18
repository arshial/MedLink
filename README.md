# FoundationApplication (iOS • SwiftUI)

A **SwiftUI** iOS prototype that bundles a few “health app” flows in one place:

- **Map** of nearby medical places (hospitals / clinics / pharmacies) using **MapKit POI search**
- **Booking** flow for doctors + **local notification** confirmation
- **Messages** tab with an **offline simulated chat** (symptom → suggested response)
- **Search** across doctors + specialties
- Simple **profile + settings** screens and a first-launch **map intro**

> ⚠️ Educational/demo app. Not medical advice. Data is mostly **mocked** and stored locally.

---

## Tech stack

- **SwiftUI**
- **MVVM-ish** structure (most logic centralized in `HomeViewModel`)
- **MapKit** (Points of Interest + natural language searches)
- **CoreLocation** (user location + “center once” behavior)
- **UserNotifications** (local notifications)
- **@AppStorage** for lightweight persistence (auth state, onboarding flag, profile image, settings toggles)

---

## Requirements

- **Xcode**: the project is configured for **iOS 26.1** deployment target (see `.xcodeproj`).
- **Swift**: 5.x

---

## Run locally

1. Open **`FoundationApplication.xcodeproj`** in Xcode.
2. Select a simulator or your device.
3. Set your **Team** and a valid **Bundle Identifier** if needed (Signing & Capabilities).
4. Build & Run.

### Important: Location permission (Info.plist)

The app requests location permission (Home tab map). Add this key to **Info.plist** (or enable “Generate Info.plist File” in Build Settings and add it there):

- `NSLocationWhenInUseUsageDescription`  
  Example value: `We use your location to show nearby hospitals, clinics, and pharmacies.`

Without this, iOS will crash the app when it tries to request permission.

---

## App overview

### Tabs

**Home**
- Header with profile access
- Filter chips (**All / Hospital / Clinic / Pharmacy**)
- Map card:
  - Default zoom is about **~1 km** around the user (or Naples fallback)
  - Data is fetched using **MapKit POI search** in a **wider region (~15 km)** so users can zoom out and still see more places
  - Region is not constantly reset (user can pan/zoom freely)
- Appointments section + Lab tests row
- Sheets:
  - **LocationDetailSheet** for map pins
  - **ProfileSheetView**
  - **ExamUploadView** (upload UI prototype)

**Book Now**
- Specialties → doctor list → booking flow
- Booking creates an appointment and triggers a **local notification** (“Appointment booked”)

**Messages**
- Threads per doctor (`ChatThread`)
- Offline simulated “doctor replies” based on keywords/symptoms (rule-based)

**Search**
- Search across **Doctors** and **Specialties**
- Discovery sections shown when search is empty

---

## How the map works (the important bits)

Map logic lives in:  
`FoundationApplication/ViewModels/HomeViewModel.swift`

Key behaviors:
- **Location permission** requested on Home appear (`requestLocationPermission()`)
- **Initial centering only once** when the first location fix arrives (prevents annoying re-centering)
- **Two regions**:
  - `activeDisplayRegion`: small (~2,000 m) for the initial user-facing zoom
  - `activeSearchRegion`: large (~30,000 m) for fetching many POIs
- Uses:
  - `MKLocalPointsOfInterestRequest` + `MKPointOfInterestCategory` for hospitals/pharmacies
  - “Natural language” queries for clinics (e.g. “clinic”, “medical clinic”, etc.)
- Deduplicates results before mapping them into your `MedicalLocation` model

---

## Project structure

```
FoundationApplication/
├─ FoundationApplicationApp.swift        # App entry + notification delegate + intro routing
├─ Info.plist                            # (currently minimal) add Location usage key here
├─ model/
│  ├─ Models.swift                        # Core models + lots of mock data (doctors/specialties/etc.)
│  └─ MessagesModel.swift                 # ChatMessage + ChatThread
├─ ViewModels/
│  ├─ HomeViewModel.swift                 # Map, filters, appointments, chat logic
│  └─ DoctorProfileBookingView.swift      # Booking-related UI
└─ Views/
   ├─ Home/                               # Home tab UI + sheets
   ├─ BookNow/                            # Auth + booking flow
   ├─ MessagesView/                       # Messages list + chat entry
   ├─ Search/                             # Search UI + placeholder
   ├─ MapIntroView/                       # First-launch intro screen
   └─ profile/                            # Settings / notifications / personal details
```

---

## Persistence (what’s saved)

The app uses `@AppStorage` for:
- `didShowMapIntro` (first launch intro)
- `auth_isAuthenticated`, `auth_savedEmail`, `auth_savedPassword`
- `user_imageBase64` (profile image)
- Several settings toggles (dark mode, etc.)

---

## Known limitations (aka “this is a prototype”)

- No backend (no real accounts, bookings, or chat)
- Credentials are stored in `@AppStorage` (not secure; Keychain would be the move)
- Notifications are local-only
- Map results depend on MapKit availability and POI coverage

---

## Suggested next upgrades

- Replace mock data with a real backend (REST / Firebase / Airtable, etc.)
- Use **Keychain** for credentials
- Use **push notifications** for real booking reminders
- Replace rule-based chat replies with:
  - structured symptom intake + triage, or
  - a real messaging backend

---

## Credits

Built as a learning / foundation project.  
Map data and POIs powered by Apple **MapKit**.
