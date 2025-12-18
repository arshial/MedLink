import SwiftUI
import UserNotifications

struct DoctorProfileBookingView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let doctor: DoctorProfile
    
    // Visit type
    @State private var selectedVisitType: String = "In-Person"
    
    // Date & time
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: String? = nil
    @State private var showCalendar: Bool = false
    
    // Auth prompts
    @State private var showLoginPrompt = false
    @State private var presentLoginSheet = false
    
    private let timeSlots = [
        "09:00 AM", "09:30 AM", "10:00 AM",
        "11:00 AM", "12:00 PM", "02:00 PM",
        "03:30 PM", "05:00 PM"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                
                // DOCTOR HEADER
                VStack(spacing: 12) {
                    Image(doctor.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(radius: 6)
                        .padding(.top, 24)
                    
                    Text(doctor.name)
                        .font(.title2.bold())
                    
                    Text(doctor.specialty.rawValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", doctor.rating))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(doctor.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // VISIT TYPE
                VStack(alignment: .leading, spacing: 14) {
                    Text("Visit type")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        visitTypeCard("In-Person", subtitle: "At clinic")
                        visitTypeCard("Telemedicine", subtitle: "Video call")
                    }
                }
                .padding(.horizontal)
                
                // DATE + TIME
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Date & time")
                            .font(.headline)
                        Spacer()
                        
                        Button {
                            showCalendar = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(formatDate(selectedDate))
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(timeSlots, id: \.self) { slot in
                                timeSlotChip(slot)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                
                // BOOK BUTTON
                Button {
                    if auth.isAuthenticated {
                        bookAppointment()
                    } else {
                        showLoginPrompt = true
                    }
                } label: {
                    Text("Book Appointment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTime != nil ? Color.blue : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                .disabled(selectedTime == nil)
            }
        }
        .navigationTitle("Doctor Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCalendar) {
            VStack {
                DatePicker("Select date",
                           selection: $selectedDate,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                
                Button("Done") {
                    showCalendar = false
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
        .alert("Sign in required", isPresented: $showLoginPrompt) {
            Button("Cancel", role: .cancel) { }
            Button("Open Login") {
                presentLoginSheet = true
            }
        } message: {
            Text("Please sign in to book an appointment.")
        }
        .sheet(isPresented: $presentLoginSheet) {
            NavigationStack {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
    
    // MARK: - Visit Type Card
    private func visitTypeCard(_ title: String, subtitle: String) -> some View {
        let isSelected = (selectedVisitType == title)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture {
            selectedVisitType = title
        }
    }
    
    // MARK: - Time Slot Chip
    private func timeSlotChip(_ slot: String) -> some View {
        let isSelected = (selectedTime == slot)
        
        return Text(slot)
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.blue.opacity(0.25) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                selectedTime = slot
            }
    }
    
    // MARK: - Date Formatter
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f.string(from: date)
    }
    
    // MARK: - Combine Date + Time
    private func combine(date: Date, time: String) -> Date? {
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        
        guard let timeDate = tf.date(from: time) else { return nil }
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return Calendar.current.date(from: components)
    }
    
    // MARK: - BOOKING ACTION
    private func bookAppointment() {
        guard let selectedTime = selectedTime else { return }
        guard let finalDate = combine(date: selectedDate, time: selectedTime) else { return }
        
        let appt = Appointment(
            doctor: Doctor(name: doctor.name, specialty: doctor.specialty, imageName: doctor.imageName),
            date: finalDate,
            locationAddress: doctor.address,
            city: "Napoli",
            country: "Italy",
            image: doctor.imageName
        )
        
        homeVM.addAppointment(appt)
        
        // Show a local notification to confirm the booking
        requestAndScheduleNotification(for: appt)
        
        // Navigate to Home tab
        homeVM.selectedTab = .home
        
        // Close the booking view
        dismiss()
    }
    
    // MARK: - Local Notification
    private func requestAndScheduleNotification(for appt: Appointment) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { settings in
            func schedule() {
                let content = UNMutableNotificationContent()
                content.title = "Appointment booked"
                content.body = "\(appt.doctor.name) • \(appt.doctor.specialty.rawValue) on \(formatted(appt.date))"
                content.sound = .default
                
                // Deliver immediately (1 second)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                center.add(request, withCompletionHandler: nil)
            }
            
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                schedule()
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { schedule() }
                }
            case .denied:
                // Optionally, show an in-app message guiding user to Settings
                break
            @unknown default:
                break
            }
        }
    }
    
    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy h:mm a"
        return f.string(from: date)
    }
}
