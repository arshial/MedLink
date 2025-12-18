import Foundation
import CoreLocation
import SwiftUI

// ==========================================================
// MARK: - FACILITY FILTER (MAP FILTER)
// ==========================================================

enum FacilityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case hospital = "Hospital"
    case clinic = "Clinic"
    case pharmacy = "Pharmacy"
    
    var id: String { rawValue }
    
    // Used for simple local search queries if needed by the ViewModel
    var searchQuery: String {
        switch self {
        case .all:
            return "hospital OR pharmacy OR clinic"
        case .hospital:
            return "hospital"
        case .clinic:
            return "clinic"
        case .pharmacy:
            return "pharmacy"
        }
    }
    
    var systemImage: String {
        switch self {
        case .all:       return "cross.case.fill"
        case .hospital:  return "cross.fill"
        case .clinic:    return "stethoscope"
        case .pharmacy:  return "pills.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all:       return .gray
        case .hospital:  return .red
        case .clinic:    return .blue
        case .pharmacy:  return .green
        }
    }
}

// ==========================================================
// MARK: - TAB BAR ENUM
// ==========================================================

enum HomeTab: String, CaseIterable, Identifiable, Hashable {
    case home = "Home"
    case bookNow = "Book now"
    case message = "Message"
    case search = "Search"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .home:      return "house"
        case .bookNow:   return "calendar.badge.plus"
        case .message:   return "bubble.left.and.bubble.right"
        case .search:    return "magnifyingglass"
        }
    }
    
    var selectedSystemImage: String {
        switch self {
        case .home:      return "house.fill"
        case .bookNow:   return "calendar.badge.plus"
        case .message:   return "bubble.left.and.bubble.right.fill"
        case .search:    return "magnifyingglass"
        }
    }
}

// ==========================================================
// MARK: - MEDICAL SPECIALTIES
// ==========================================================

enum MedicalSpecialty: String, CaseIterable, Identifiable, Hashable {
    case cardiology     = "Cardiology"
    case neurology      = "Neurology"
    case primaryCare    = "Primary Care"
    case dermatology    = "Dermatology"
    case pediatrics     = "Pediatrics"
    case orthopedics    = "Orthopedics"
    case psychiatry     = "Psychiatry"
    case urology        = "Urology"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .cardiology: return "heart.fill"
        case .neurology:  return "brain.head.profile"
        case .primaryCare: return "cross.case.fill"
        case .dermatology: return "list.clipboard"
        case .pediatrics: return "figure.child"
        case .orthopedics: return "figure.walk"
        case .psychiatry:  return "person.crop.circle.badge.questionmark.fill"
        case .urology:     return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cardiology: return .red
        case .neurology:  return .purple
        case .primaryCare: return .blue
        case .dermatology: return .pink
        case .pediatrics: return .orange
        case .orthopedics: return .green
        case .psychiatry:  return .indigo
        case .urology:     return .teal
        }
    }
    
    var shortDescription: String {
        switch self {
        case .cardiology:     return "Heart & circulation"
        case .neurology:      return "Brain & nerves"
        case .primaryCare:    return "General medical support"
        case .dermatology:    return "Skin & diseases"
        case .pediatrics:     return "Children's health"
        case .orthopedics:    return "Bones & joints"
        case .psychiatry:     return "Mental health"
        case .urology:        return "Kidneys & urinary system"
        }
    }
}

// ==========================================================
// MARK: - MEDICAL LOCATION MODEL
// ==========================================================

struct MedicalLocation: Identifiable {
    let id = UUID()
    let name: String
    let type: FacilityFilter
    let coordinate: CLLocationCoordinate2D
    var addressPlaceholder: String
}

// ==========================================================
// MARK: - DOCTOR MODEL
// ==========================================================

struct Doctor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let specialty: MedicalSpecialty
    let imageName: String
}

// ==========================================================
// MARK: - APPOINTMENT MODEL
// ==========================================================

enum AppointmentStatus: String {
    case upcoming
    case completed
    case cancelled
}

struct Appointment: Identifiable {
    let id = UUID()
    let doctor: Doctor
    let date: Date
    let locationAddress: String
    let city: String
    let country: String
    var status: AppointmentStatus = .upcoming
    var image: String
}

// ==========================================================
// MARK: - DOCTOR PROFILE MODEL (LIST + BOOKING)
// ==========================================================

struct DoctorProfile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let specialty: MedicalSpecialty
    let rating: Double
    let languages: [String]
    let address: String
    let imageName: String
}

// ==========================================================
// MARK: - SAMPLE DOCTORS FUNCTION
// ==========================================================

func doctorProfiles(for specialty: MedicalSpecialty) -> [DoctorProfile] {
    let commonLanguages = ["English", "Italian"]
    
    switch specialty {
        
    case .cardiology:
        return [
            DoctorProfile(name: "Dr. Ardalan Hemant", specialty: specialty, rating: 4.8, languages: commonLanguages, address: "Via Roma 12, Napoli", imageName: "cardio1"),
            DoctorProfile(name: "Dr. Giulia Moretti", specialty: specialty, rating: 4.6, languages: commonLanguages, address: "Via Marina 80, Napoli", imageName: "cardio2"),
            DoctorProfile(name: "Dr. Davide Conti", specialty: specialty, rating: 4.9, languages: commonLanguages, address: "Piazza Garibaldi 5, Napoli", imageName: "cardio3")
        ]
        
    case .neurology:
        return [
            DoctorProfile(name: "Dr. Elena Bianchi", specialty: specialty, rating: 4.7, languages: commonLanguages, address: "Via Foria 100, Napoli", imageName: "neuro1"),
            DoctorProfile(name: "Dr. Marco Esposito", specialty: specialty, rating: 4.4, languages: commonLanguages, address: "Corso Umberto 55, Napoli", imageName: "neuro2"),
            DoctorProfile(name: "Dr. Serena Lupo", specialty: specialty, rating: 4.9, languages: commonLanguages, address: "Via Chiaia 20, Napoli", imageName: "neuro3")
        ]
        
    case .primaryCare:
        return [
            DoctorProfile(name: "Dr. Luca Gallo", specialty: specialty, rating: 4.5, languages: commonLanguages, address: "Via Dante 10, Napoli", imageName: "pc1"),
            DoctorProfile(name: "Dr. Giulia Costa", specialty: specialty, rating: 4.3, languages: commonLanguages, address: "Via Toledo 77, Napoli", imageName: "pc2"),
            DoctorProfile(name: "Dr. Antonio Romano", specialty: specialty, rating: 4.7, languages: commonLanguages, address: "Via Manzoni 8, Napoli", imageName: "pc3")
        ]
        
    case .dermatology:
        return [
            DoctorProfile(name: "Dr. Sara Esfandiari", specialty: specialty, rating: 4.9, languages: commonLanguages, address: "Via dei Mille 44, Napoli", imageName: "derm1"),
            DoctorProfile(name: "Dr. Alessio Ricci", specialty: specialty, rating: 4.4, languages: commonLanguages, address: "Via Partenope 18, Napoli", imageName: "derm2"),
            DoctorProfile(name: "Dr. Martina Romano", specialty: specialty, rating: 4.6, languages: commonLanguages, address: "Via Posillipo 33, Napoli", imageName: "derm3")
        ]
        
    case .pediatrics:
        return [
            DoctorProfile(name: "Dr. Ava Naderi", specialty: specialty, rating: 4.8, languages: commonLanguages, address: "Via Manzoni 70, Napoli", imageName: "ped1"),
            DoctorProfile(name: "Dr. Matteo Gatti", specialty: specialty, rating: 4.5, languages: commonLanguages, address: "Via Posillipo 30, Napoli", imageName: "ped2"),
            DoctorProfile(name: "Dr. Chiara Mancini", specialty: specialty, rating: 4.2, languages: commonLanguages, address: "Vomero 22, Napoli", imageName: "ped3")
        ]
        
    case .orthopedics:
        return [
            DoctorProfile(name: "Dr. Paolo Conti", specialty: specialty, rating: 4.6, languages: commonLanguages, address: "Via Caracciolo 20, Napoli", imageName: "ortho1"),
            DoctorProfile(name: "Dr. Elena Giordano", specialty: specialty, rating: 4.3, languages: commonLanguages, address: "Via Pessina 5, Napoli", imageName: "ortho2"),
            DoctorProfile(name: "Dr. Lorenzo Gallo", specialty: specialty, rating: 4.8, languages: commonLanguages, address: "Via Tasso 42, Napoli", imageName: "ortho3")
        ]
        
    @unknown default:
        return []
    }
}
