import Foundation
import Combine
import MapKit
import CoreLocation
import SwiftUI

// Naples center
private let naplesCoordinate = CLLocationCoordinate2D(latitude: 40.8518, longitude: 14.2681)

private let naplesDisplayRegion = MKCoordinateRegion(
    center: naplesCoordinate,
    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.06)
)

private let naplesSearchRegion = MKCoordinateRegion(
    center: naplesCoordinate,
    span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.8)
)

private let clinicTerms: [String] = [
    "Clinica",
    "Clinica Privata",
    "Centro Medico",
    "Casa di Cura"
]

@MainActor
final class HomeViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // MARK: - User Profile
    struct UserProfile {
        var fullName: String
        var email: String
        var phone: String
        var address: String
        var imageName: String
    }
    
    @Published var userProfile: UserProfile = UserProfile(
        fullName: "",
        email: ".",
        phone: "",
        address: "",
        imageName: ""
    )
    
    // MARK: - Tabs / Filters
    @Published var selectedTab: HomeTab = .home
    
    // When the filter changes, re-run the Naples query (no location permission needed)
    @Published var selectedFilter: FacilityFilter = .all {
        didSet {
            performSearch()
        }
    }
    
    // MARK: - Map
    @Published var region: MKCoordinateRegion
    @Published private(set) var locations: [MedicalLocation] = []
    // User's current location (updated via CLLocationManager)
    @Published var userLocation: CLLocation? = nil
    @Published var locationAuthorization: CLAuthorizationStatus = .notDetermined

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = CLLocationManager()
    private var searchTask: Task<Void, Never>?
    private var lastSearchDate: Date?
    private let minSearchInterval: TimeInterval = 2.0

    // 1) Added flag: only center/zoom to user once when first location fix arrives
    private var didSetInitialUserRegion = false

    // ACTION 3: Center-on-open flag
    private var centerMapOnNextLocationUpdate = false

    // Prefer user location; fallback to Naples
    // 3) Wide search region (~15 km radius) to fetch many places
    private var activeSearchRegion: MKCoordinateRegion {
        let center = (userLocation?.coordinate ?? naplesCoordinate)
        // Big fetch area (~15km radius)
        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: 30_000,
            longitudinalMeters: 30_000
        )
    }

    // 2) Display zoom ~1 km (only a default zoom, do not force it repeatedly)
    private var activeDisplayRegion: MKCoordinateRegion {
        let center = (userLocation?.coordinate ?? naplesCoordinate)
        return MKCoordinateRegion(
            center: center,
            latitudinalMeters: 2_000,
            longitudinalMeters: 2_000
        )
    }
    
    // MARK: - Preview Detection
    private var isPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
#else
        return false
#endif
    }
    
    // MARK: - Init
    override init() {
        // 4) Default to 1 km around Naples until we get user location (avoid using self before super.init)
        self.region = MKCoordinateRegion(
            center: naplesCoordinate,
            latitudinalMeters: 2_000,
            longitudinalMeters: 2_000
        )
        super.init()
        
        // Configure location manager and request permission
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationAuthorization = locationManager.authorizationStatus
        requestLocationPermission()
        
        reloadUserProfileFromStorage()
        
        appointments = []
        chatThreads = []
        
        if isPreview {
            seedPreviewData()
            return
        }
        
        // Initial load (no permission required)
        performSearch()
    }
    
    // MARK: - Appointments & Messages
    @Published var appointments: [Appointment] = []
    var hasUpcomingAppointments: Bool { !appointments.isEmpty }
    @Published var chatThreads: [ChatThread] = []
    
    // MARK: - Appointment helpers (fix missing dynamic members)
    func addAppointment(_ appt: Appointment) {
        // Save the appointment
        appointments.append(appt)
        
        // Ensure a chat thread exists for this doctor and seed a welcome
        ensureChatThreadExists(for: appt.doctor)
        appendDoctorWelcomeIfNeeded(for: appt.doctor)
        
        // Optional: switch to Messages tab so the user sees the new thread immediately.
        // selectedTab = .message
    }
    
    func deleteAppointment(_ id: UUID) {
        // Find the appointment to get its doctor
        guard let appt = appointments.first(where: { $0.id == id }) else {
            // Nothing to delete
            return
        }
        
        // Remove the appointment
        appointments.removeAll { $0.id == id }
        
        // If no other appointments exist for the same doctor, remove the chat thread too
        let stillHasAppointmentsWithDoctor = appointments.contains { $0.doctor.id == appt.doctor.id }
        if !stillHasAppointmentsWithDoctor {
            chatThreads.removeAll { $0.doctor.id == appt.doctor.id }
        }
    }
    
    // MARK: - Search across Naples (no location permission)
    func performSearch() {
        if isPreview { return }
        
        // Simple rate limit: skip if called too frequently
        if let last = lastSearchDate, Date().timeIntervalSince(last) < minSearchInterval {
            return
        }
        lastSearchDate = Date()
        
        // Cancel any in-flight search
        searchTask?.cancel()
        
        searchTask = Task { [selectedFilter] in
            let items = await collectNaplesItems(filter: selectedFilter)
            let mapped = mapItemsToLocations(items, selectedFilter: selectedFilter, defaultAddress: "Nearby")
            await MainActor.run {
                // 5) Do NOT reset region here; keep user's zoom/pan
                self.locations = mapped
            }
        }
    }
    
    // MARK: - Chat Logic
    private func ensureChatThreadExists(for doctor: Doctor) {
        if chatThreads.first(where: { $0.doctor.id == doctor.id }) == nil {
            chatThreads.append(ChatThread(doctor: doctor, messages: [], isTyping: false))
        }
    }
    
    private func appendDoctorWelcomeIfNeeded(for doctor: Doctor) {
        guard let idx = chatThreads.firstIndex(where: { $0.doctor.id == doctor.id }) else { return }
        if chatThreads[idx].messages.isEmpty {
            chatThreads[idx].messages.append(
                ChatMessage(sender: .doctor,
                            text: "Hello, this is \(doctor.name). I can offer general guidance. For emergencies, call local services or go to the nearest ER.",
                            date: Date())
            )
        }
    }
    
    func sendMessage(_ text: String, to doctor: Doctor) {
        if chatThreads.first(where: { $0.doctor.id == doctor.id }) == nil {
            chatThreads.append(ChatThread(doctor: doctor, messages: []))
        }
        guard let index = chatThreads.firstIndex(where: { $0.doctor.id == doctor.id }) else { return }
        chatThreads[index].messages.append(ChatMessage(sender: .user, text: text, date: Date()))
        simulateDoctorReplyOffline(for: text, to: doctor)
    }
    
    // MARK: - Offline simulated doctor
    private func simulateDoctorReplyOffline(for userText: String, to doctor: Doctor) {
        guard let idx = chatThreads.firstIndex(where: { $0.doctor.id == doctor.id }) else { return }
        chatThreads[idx].isTyping = true
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64.random(in: 700_000_000...1_300_000_000))
            let reply = SymptomEngine.shared.generateReply(userText: userText, specialty: doctor.specialty)
            chatThreads[idx].messages.append(ChatMessage(sender: .doctor, text: reply, date: Date()))
            chatThreads[idx].isTyping = false
        }
    }
    
    // MARK: - Preview Data
    private func seedPreviewData() {
        let center = naplesCoordinate
        self.region = naplesDisplayRegion
        
        self.locations = [
            MedicalLocation(name: "Preview Hospital", type: .hospital, coordinate: center, addressPlaceholder: "Via Roma 1, Napoli"),
            MedicalLocation(name: "Preview Clinic", type: .clinic, coordinate: CLLocationCoordinate2D(latitude: center.latitude + 0.01, longitude: center.longitude + 0.01), addressPlaceholder: "Via Napoli 2, Napoli"),
            MedicalLocation(name: "Preview Pharmacy", type: .pharmacy, coordinate: CLLocationCoordinate2D(latitude: center.latitude - 0.01, longitude: center.longitude - 0.01), addressPlaceholder: "Piazza Dante 3, Napoli")
        ]
        
        let sampleDoctor = Doctor(name: "Dr. Preview Example", specialty: .cardiology, imageName: "cardio1")
        let sampleAppt = Appointment(
            doctor: sampleDoctor,
            date: Date().addingTimeInterval(3600 * 24),
            locationAddress: "Via Roma 1",
            city: "Napoli",
            country: "Italia",
            status: .upcoming,
            image: "cardio1"
        )
        self.appointments = [sampleAppt]
        
        let sampleThread = ChatThread(
            doctor: sampleDoctor,
            messages: [
                ChatMessage(sender: .doctor, text: "Welcome!", date: Date().addingTimeInterval(-3600)),
                ChatMessage(sender: .user, text: "Thank you doctor.", date: Date().addingTimeInterval(-1800))
            ],
            isTyping: false
        )
        self.chatThreads = [sampleThread]
    }
    
    // MARK: - SymptomEngine
    private struct SymptomEngine {
        static let shared = SymptomEngine()
        
        private struct Domain {
            let name: String
            let symptoms: [String]
            let redFlags: [String]
            let homeCare: [String]
            let monitor: [String]
            let likely: [String]
            
            func score(for text: String) -> Int {
                var s = 0
                for w in symptoms { if text.contains(w) { s += 1 } }
                return s
            }
            func containsAny(_ text: String, in words: [String]) -> Bool {
                words.contains { text.contains($0) }
            }
        }
        
        private let resp = Domain(
            name: "Respiratory",
            symptoms: ["cough","coughing","phlegm","sputum","wheeze","wheezing","shortness of breath","breathless","difficulty breathing","runny nose","congestion","sore throat","throat pain","hoarse","hoarseness"],
            redFlags: ["shortness of breath","difficulty breathing","blue lips","oxygen","low oxygen","severe chest pain","high fever","confusion"],
            homeCare: ["Rest, hydrate, and use warm fluids or honey for cough (if not contraindicated).","Consider saline nasal rinses and steam inhalation for congestion.","Use over‑the‑counter fever reducers if needed and tolerated."],
            monitor: ["Breathing difficulty, persistent high fever, chest pain, or worsening cough.","Dehydration signs (reduced urination, dizziness)."],
            likely: ["Viral upper respiratory infection (common cold or flu) is common.","Allergies or irritation can contribute to cough and congestion."]
        )
        private let cardio = Domain(
            name: "Cardiology",
            symptoms: ["chest pain","pressure","tightness","palpitations","fast heartbeat","shortness of breath","swelling legs","edema","fainting","syncope"],
            redFlags: ["severe chest pain","pain radiating to arm","pain radiating to jaw","shortness of breath","fainting","cold sweats","confusion"],
            homeCare: ["Avoid exertion and heavy meals; rest in a comfortable position.","Track blood pressure and pulse if possible."],
            monitor: ["Worsening chest discomfort, breathlessness, dizziness, or fainting.","Swelling, rapid weight gain, or irregular pulse."],
            likely: ["Musculoskeletal strain, reflux, or anxiety can mimic cardiac pain.","However, cardiac causes must be considered depending on risk factors."]
        )
        private let derm = Domain(
            name: "Dermatology",
            symptoms: ["rash","skin","itch","itchy","hives","red spots","irritation","eczema","dermatitis","acne","pimples","lesion","scaly","flaky"],
            redFlags: ["rapidly spreading redness","fever with rash","severe pain","blistering widespread","mucosal involvement","swelling of lips or tongue"],
            homeCare: ["Keep the area clean and dry; avoid harsh products and hot showers.","Use a gentle moisturizer; consider fragrance‑free emollients."],
            monitor: ["Rapid spread, fever, or signs of infection (increasing redness, warmth, pus).","Severe itch or pain not improving with gentle care."],
            likely: []
        )
        private let gi = Domain(
            name: "Gastrointestinal",
            symptoms: ["stomach","abdomen","abdominal","nausea","vomit","vomiting","diarrhea","diarrhoea","constipation","cramp","cramping","bloating","heartburn","reflux","acid","indigestion"],
            redFlags: ["severe abdominal pain","rigid abdomen","blood in stool","black stool","persistent vomiting","signs of dehydration","fever with pain"],
            homeCare: ["Small sips of fluids (oral rehydration); bland foods as tolerated.","Avoid heavy, spicy, or fatty meals until better."],
            monitor: ["Persistent vomiting/diarrhea, blood in stool, high fever, or severe pain.","Signs of dehydration: dizziness, dry mouth, infrequent urination."],
            likely: []
        )
        private let neuro = Domain(
            name: "Neurology",
            symptoms: ["headache","migraine","head pain","dizzy","dizziness","lightheaded","vertigo","numbness","tingling","weakness","tremor","seizure"],
            redFlags: ["sudden worst headache","weakness on one side","slurred speech","confusion","fainting","seizure","vision loss"],
            homeCare: ["Rest in a quiet, dark room; hydrate; consider gentle caffeine.","Track triggers (stress, dehydration, screen time) and use simple analgesics if appropriate."],
            monitor: ["New neurological deficits, severe or sudden headache, persistent vomiting.","Worsening frequency or severity despite home care."],
            likely: []
        )
        private let ortho = Domain(
            name: "Orthopedics",
            symptoms: ["sprain","strain","twisted","fracture","broken","swollen","swelling","bruise","bruised","joint pain","knee pain","shoulder pain","back pain"],
            redFlags: ["deformity","inability to bear weight","numb limb","severe swelling","open wound","fever with joint pain"],
            homeCare: ["RICE: rest, ice (15–20 min), compression, elevation for 24–48 hours.","Avoid heavy strain; consider gentle mobility as pain allows."],
            monitor: ["Worsening pain/swelling, inability to move, or numbness/tingling.","Persistent pain limiting activity."],
            likely: []
        )
        private let uro = Domain(
            name: "Urology",
            symptoms: ["urine","urination","pee","burning urination","uti","frequent urination","hematuria","blood in urine","flank pain","kidney pain"],
            redFlags: ["fever with urinary symptoms","flank pain with fever","severe pain","blood clots in urine","retention (unable to urinate)"],
            homeCare: ["Hydrate well; avoid bladder irritants (caffeine, alcohol, spicy foods).","Consider urinary alkalinizers if appropriate."],
            monitor: ["Fever, back/flank pain, worsening burning or frequency.","Any visible blood in urine persisting."],
            likely: []
        )
        private let psych = Domain(
            name: "Mental Health",
            symptoms: ["anxiety","panic","stress","worried","insomnia","sleep","depressed","low mood"],
            redFlags: ["thoughts of self‑harm","suicidal","harming yourself","harming others","severe agitation","confusion"],
            homeCare: ["Try slow breathing (4‑7‑8), regular sleep schedule, and daily light activity.","Limit caffeine and alcohol; consider short relaxation exercises."],
            monitor: ["Worsening mood, sleep disruption, inability to function.","Any thoughts of self‑harm — seek urgent help immediately."],
            likely: []
        )
        private let pediatrics = Domain(
            name: "Pediatrics",
            symptoms: ["child","kid","baby","toddler","infant","my son","my daughter","fever","cough","rash","vomit","diarrhea"],
            redFlags: ["lethargy","breathing difficulty","persistent high fever","dehydration","stiff neck","seizure","non‑blanching rash"],
            homeCare: ["Ensure hydration; monitor wet diapers/urination.","Use weight‑based fever reducers if appropriate and advised."],
            monitor: ["Breathing, activity, appetite, and hydration.","Any red‑flag signs above — seek urgent care."],
            likely: []
        )
        private let general = Domain(
            name: "General",
            symptoms: ["pain","ache","sore","tired","fatigue","weak","weakness","fever","temperature","sick"],
            redFlags: ["severe pain","shortness of breath","confusion","persistent high fever","fainting","severe bleeding","stroke signs"],
            homeCare: ["Rest, hydration, and simple over‑the‑counter relief as appropriate.","Track symptoms (onset, duration, triggers) to share in a visit."],
            monitor: ["Worsening symptoms, new red flags, or persistence beyond a few days.","Any severe or rapidly progressing issues."],
            likely: []
        )
        private var domains: [Domain] { [resp, cardio, derm, gi, neuro, ortho, uro, psych, pediatrics, general] }
        
        private let durationPatterns: [String] = [
            "for [0-9]+ days","for [0-9]+ day","for [0-9]+ weeks","for [0-9]+ week",
            "since yesterday","since last night","since today","for a few days","for several days",
            "for months","for years","for a while"
        ]
        private func containsAny(_ text: String, in words: [String]) -> Bool { words.contains { text.contains($0) } }
        private func extractAll(_ text: String, from words: [String]) -> [String] { words.filter { text.contains($0) } }
        private func extractDuration(_ text: String) -> String? {
            for p in durationPatterns {
                let normalized = p.replacingOccurrences(of: "[0-9]+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                if normalized.count > 2, text.contains(normalized) {
                    if let num = findFirstNumber(in: text), p.contains("[0-9]+") {
                        return p.replacingOccurrences(of: "[0-9]+", with: "\(num)")
                    } else { return normalized }
                }
            }
            if let m = text.range(of: #"for (\d+)\s+(day|days|week|weeks|hour|hours)"#, options: .regularExpression) {
                return String(text[m])
            }
            return nil
        }
        private func extractSeverity(_ text: String) -> String? {
            let list = ["mild","moderate","severe","worst","worse","worsening","intense","sharp","dull","throbbing"]
            return list.first { text.contains($0) }
        }
        private func findFirstNumber(in text: String) -> Int? {
            if let r = text.range(of: #"\d+"#, options: .regularExpression) { return Int(text[r]) }
            return nil
        }
        private func containsCriticalRedFlags(_ text: String) -> Bool {
            let rf = ["severe chest pain","trouble breathing","shortness of breath","confusion","fainting","stroke","weakness on one side","slurred speech","severe bleeding","rigid abdomen","black stool","blood in stool","worst headache"]
            return containsAny(text, in: rf)
        }
        private func specialtyNote(_ specialty: MedicalSpecialty, text: String) -> String? {
            switch specialty {
            case .cardiology:
                return "Specialty note (Cardiology): Track blood pressure and pulse if possible. Avoid exertion and heavy meals. If chest pain is severe, radiates to arm/jaw, or occurs with breathlessness or fainting, seek urgent care."
            case .neurology:
                return "Specialty note (Neurology): For headaches or dizziness, note triggers and any neurological changes (weakness, numbness, speech or vision issues). Sudden severe headache or new deficits require urgent evaluation."
            case .primaryCare:
                return "Specialty note (Primary Care): We can triage broadly and coordinate tests or referrals as needed."
            case .dermatology:
                return "Specialty note (Dermatology): Gentle skincare, fragrance‑free moisturizers, and avoiding irritants can help while we assess."
            case .pediatrics:
                return "Specialty note (Pediatrics): Focus on hydration, activity, appetite, and temperature trends. Seek urgent care for breathing difficulty, lethargy, persistent high fever, or a non‑blanching rash."
            case .orthopedics:
                return "Specialty note (Orthopedics): Use RICE for strains/sprains. If deformity, inability to bear weight, or numbness occurs, seek prompt evaluation."
            @unknown default:
                return nil
            }
        }
        
        func generateReply(userText: String, specialty: MedicalSpecialty) -> String {
            return generateReplyInternal(userText: userText, specialty: specialty)
        }
        
        private func generateReplyInternal(userText: String, specialty: MedicalSpecialty) -> String {
            let text = userText.lowercased()
            let dur = extractDuration(text)
            let sev = extractSeverity(text)
            let isChild = containsAny(text, in: ["child","kid","baby","toddler","infant","my son","my daughter"])
            let isPregnant = containsAny(text, in: ["pregnant","pregnancy","expecting","trimester"])
            let comorbid = extractAll(text, from: ["diabetes","hypertension","high blood pressure","asthma","copd","heart disease","kidney disease","cancer"])
            
            let hits = domains.map { ($0, $0.score(for: text)) }.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }
            let hasRedFlags = hits.contains { $0.0.containsAny(text, in: $0.0.redFlags) }
            let topDomains = Array(hits.prefix(2)).map { $0.0 }
            
            var sections: [String] = []
            if topDomains.isEmpty {
                sections.append("Thanks for the details. I’ll share general guidance based on what you described.")
            } else {
                let likelyLines = topDomains.flatMap { $0.likely }.prefix(3)
                if !likelyLines.isEmpty {
                    sections.append("What it might be (non‑diagnostic):\n- " + likelyLines.joined(separator: "\n- "))
                }
            }
            if let specNote = specialtyNote(specialty, text: text) { sections.append(specNote) }
            
            var contextParts: [String] = []
            if let dur { contextParts.append("Duration: \(dur)") }
            if let sev { contextParts.append("Severity: \(sev)") }
            if isChild { contextParts.append("Context: child involved") }
            if isPregnant { contextParts.append("Context: pregnancy") }
            if !comorbid.isEmpty { contextParts.append("Comorbidities: \(comorbid.joined(separator: ", "))") }
            if !contextParts.isEmpty { sections.append(contextParts.joined(separator: " • ")) }
            
            let homeCare = topDomains.flatMap { $0.homeCare }.prefix(4)
            if !homeCare.isEmpty {
                sections.append("Home care:\n- " + homeCare.joined(separator: "\n- "))
            } else {
                sections.append("Home care:\n- Rest, hydrate, and use simple over‑the‑counter relief if appropriate.\n- Track symptoms and avoid known triggers if possible.")
            }
            let monitor = topDomains.flatMap { $0.monitor }.prefix(4)
            if !monitor.isEmpty {
                sections.append("What to monitor:\n- " + monitor.joined(separator: "\n- "))
            } else {
                sections.append("What to monitor:\n- Worsening symptoms, new red flags, or persistence beyond a few days.")
            }
            if hasRedFlags || containsCriticalRedFlags(text) {
                sections.append("Urgent care: If you develop severe chest pain, trouble breathing, confusion, severe bleeding, fainting, or stroke‑like symptoms, seek emergency services immediately.")
            } else {
                sections.append("If symptoms worsen or don’t improve, consider booking a visit so we can evaluate further.")
            }
            return sections.joined(separator: "\n\n")
        }
    }
    
    // Reload user profile data from AppStorage so UI updates everywhere
    func reloadUserProfileFromStorage() {
        userProfile.fullName = UserDefaults.standard.string(forKey: "user_fullName") ?? userProfile.fullName
        userProfile.email = UserDefaults.standard.string(forKey: "user_email") ?? userProfile.email
        userProfile.phone = UserDefaults.standard.string(forKey: "user_phone") ?? userProfile.phone
        userProfile.address = UserDefaults.standard.string(forKey: "user_address") ?? userProfile.address
        userProfile.imageName = UserDefaults.standard.string(forKey: "user_imageName") ?? userProfile.imageName
    }
    
    // Call this after login/signup to refresh profile everywhere
    func onUserAuthenticated() {
        reloadUserProfileFromStorage()
    }

    // ACTION 3: Helper to prepare map centering when Home/Map appears
    func prepareMapForDisplay() {
        // When Home/Map appears, we want to re-center to 1km.
        centerMapOnNextLocationUpdate = true

        // If we already have a location, center immediately.
        if userLocation != nil {
            region = activeDisplayRegion
            centerMapOnNextLocationUpdate = false
        }
    }
    
    // MARK: - Search helpers (off-main)
    private func collectNaplesItems(filter: FacilityFilter) async -> [MKMapItem] {
        func poiSearch(category: MKPointOfInterestCategory) async -> [MKMapItem] {
            let req = MKLocalPointsOfInterestRequest(coordinateRegion: activeSearchRegion)
            req.pointOfInterestFilter = MKPointOfInterestFilter(including: [category])
            let search = MKLocalSearch(request: req)
            do {
                let response = try await search.start()
                return response.mapItems
            } catch {
                return []
            }
        }
        
        func naturalSearch(query: String) async -> [MKMapItem] {
            let request = MKLocalSearch.Request()
            request.region = activeSearchRegion
            request.naturalLanguageQuery = query
            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                return response.mapItems
            } catch {
                return []
            }
        }
        
        switch filter {
        case .all:
            async let hospitals = poiSearch(category: .hospital)
            async let pharmacies = poiSearch(category: .pharmacy)
            let clinics = await withTaskGroup(of: [MKMapItem].self) { group -> [MKMapItem] in
                for term in clinicTerms {
                    group.addTask { await naturalSearch(query: term) }
                }
                var acc: [MKMapItem] = []
                for await r in group { acc.append(contentsOf: r) }
                return acc
            }
            let results = await [hospitals, pharmacies].flatMap { $0 } + clinics
            return dedup(results)
            
        case .hospital:
            return await poiSearch(category: .hospital)
            
        case .pharmacy:
            return await poiSearch(category: .pharmacy)
            
        case .clinic:
            let clinics = await withTaskGroup(of: [MKMapItem].self) { group -> [MKMapItem] in
                for term in clinicTerms {
                    group.addTask { await naturalSearch(query: term) }
                }
                var acc: [MKMapItem] = []
                for await r in group { acc.append(contentsOf: r) }
                return acc
            }
            return dedup(clinics)
        }
    }
    
    private func dedup(_ items: [MKMapItem]) -> [MKMapItem] {
        var seen = Set<String>()
        return items.filter { item in
            let lat = (item.placemark.coordinate.latitude * 1e5).rounded() / 1e5
            let lon = (item.placemark.coordinate.longitude * 1e5).rounded() / 1e5
            let key = "\(item.name ?? "")-\(lat)-\(lon)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }
    
    private func mapItemsToLocations(_ items: [MKMapItem], selectedFilter: FacilityFilter, defaultAddress: String) -> [MedicalLocation] {
        items.map { item in
            let facilityType: FacilityFilter
            if selectedFilter == .all {
                if let cat = item.pointOfInterestCategory {
                    switch cat {
                    case .pharmacy: facilityType = .pharmacy
                    case .hospital: facilityType = .hospital
                    default:
                        facilityType = classifyByName(item.name)
                    }
                } else {
                    facilityType = classifyByName(item.name)
                }
            } else {
                facilityType = selectedFilter
            }
            return MedicalLocation(
                name: item.name ?? "Unknown",
                type: facilityType,
                coordinate: item.placemark.coordinate,
                addressPlaceholder: item.placemark.title ?? defaultAddress
            )
        }
    }
    
    private func classifyByName(_ name: String?) -> FacilityFilter {
        let n = (name ?? "").lowercased()
        if n.contains("pharm") || n.contains("farmac") { return .pharmacy }
        if n.contains("hospital") || n.contains("ospedal") { return .hospital }
        if n.contains("clinic") || n.contains("clinica")
            || n.contains("ambulator")
            || n.contains("poliambulator") || n.contains("policlin")
            || n.contains("medical center")
            || n.contains("centro medico") || n.contains("centro specialistico") || n.contains("polispecial")
            || n.contains("studio medico")
            || n.contains("casa di cura")
            || n.contains("centro diagnostico") || n.contains("centro salute")
        { return .clinic }
        return .hospital
    }
    
    // MARK: - Location permission + delegate callbacks
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorization = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        userLocation = loc

        if !didSetInitialUserRegion {
            region = activeDisplayRegion
            didSetInitialUserRegion = true
        } else if centerMapOnNextLocationUpdate {
            region = activeDisplayRegion
            centerMapOnNextLocationUpdate = false
        }

        performSearch()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
