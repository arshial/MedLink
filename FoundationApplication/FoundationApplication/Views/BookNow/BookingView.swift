import SwiftUI
import UserNotifications

struct BookingView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    let doctor: DoctorProfile
    
    // VISIT TYPE
    @State private var selectedVisitType: String = "In-Person"
    
    // DATE & TIME
    @State private var selectedTime: String? = nil
    @State private var selectedDate: Date = Date()
    @State private var isDatePickerPresented: Bool = false

    // Auth prompts
    @State private var showLoginPrompt = false
    @State private var presentLoginSheet = false
    
    private let timeSlots: [String] = [
        "09:30 AM", "10:00 AM", "11:30 AM",
        "02:00 PM", "03:30 PM", "05:00 PM"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // DOCTOR HEADER
                VStack(spacing: 12) {
                    Image(doctor.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                        .padding(.top, 24)
                    
                    Text(doctor.name)
                        .font(.title2.weight(.bold))
                    
                    Text(doctor.specialty.rawValue)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(doctor.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // VISIT TYPE SELECTOR
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select consultation type")
                        .font(.headline)
                    
                    HStack(spacing: 14) {
                        visitTypeCard(title: "In-Person", subtitle: "Visit at clinic", selected: selectedVisitType == "In-Person")
                            .onTapGesture { selectedVisitType = "In-Person" }
                        
                        visitTypeCard(title: "Telemedicine", subtitle: "Video call", selected: selectedVisitType == "Telemedicine")
                            .onTapGesture { selectedVisitType = "Telemedicine" }
                    }
                }
                .padding(.horizontal, 20)
                
                
                // DATE + TIME
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Choose date & time")
                            .font(.headline)
                        
                        Spacer()
                        
                        // CALENDAR BUTTON
                        Button {
                            isDatePickerPresented = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(formattedDate(selectedDate))
                                    .font(.subheadline)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    
                    // TIME SLOTS
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(timeSlots, id: \.self) { slot in
                                timeSlotChip(slot)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 0)
                
                // BOOK NOW BUTTON
                Button {
                    guard selectedTime != nil else { return }
                    if auth.isAuthenticated {
                        bookNow()
                    } else {
                        showLoginPrompt = true
                    }
                } label: {
                    Text("Book now")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((selectedTime != nil) ? Color.blue : Color.gray, in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedTime == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .alert("Sign in required", isPresented: $showLoginPrompt) {
                    Button("Cancel", role: .cancel) { }
                    Button("Open Login") {
                        presentLoginSheet = true
                    }
                } message: {
                    Text("Please sign in to book an appointment.")
                }
                .sheet(isPresented: $presentLoginSheet, onDismiss: {
                    // If the user signed in successfully, proceed with booking automatically.
                    if auth.isAuthenticated, selectedTime != nil {
                        bookNow()
                    }
                }) {
                    NavigationStack {
                        LoginView()
                            .environmentObject(auth)
                    }
                }
            }
        }
        .navigationTitle("Booking")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isDatePickerPresented) {
            VStack {
                DatePicker(
                    "Select date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Button("Done") { isDatePickerPresented = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - COMPONENTS
    
    private func visitTypeCard(title: String, subtitle: String, selected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(subtitle).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(selected ? Color.blue.opacity(0.15) : Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(selected ? Color.blue : Color(.systemGray4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
    private func timeSlotChip(_ slot: String) -> some View {
        let isSelected = (slot == selectedTime)
        return Text(slot)
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { selectedTime = slot }
    }
    
    
    // MARK: - HELPERS
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f.string(from: date)
    }
    
    private func combine(date: Date, time: String) -> Date? {
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"
        guard let t = tf.date(from: time) else { return nil }
        
        var c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let tc = Calendar.current.dateComponents([.hour, .minute], from: t)
        c.hour = tc.hour
        c.minute = tc.minute
        return Calendar.current.date(from: c)
    }
    
    
    // MARK: - BOOK ACTION
    
    private func bookNow() {
        guard let selectedTime else { return }
        guard let finalDate = combine(date: selectedDate, time: selectedTime) else { return }
        
        let appt = Appointment(
            doctor: Doctor(name: doctor.name, specialty: doctor.specialty, imageName: doctor.imageName),
            date: finalDate,
            locationAddress: doctor.address,
            city: "Napoli",
            country: "Italia",
            status: .upcoming,
            image: doctor.imageName
        )
        
        homeVM.addAppointment(appt)
        requestAndScheduleNotification(for: appt)
        homeVM.selectedTab = .home
        dismiss()
    }
    
    // MARK: - Local Notification
    
    private func requestAndScheduleNotification(for appt: Appointment) {
        let center = UNUserNotificationCenter.current()
        
        func schedule() {
            let content = UNMutableNotificationContent()
            content.title = "Appointment booked"
            content.body = "\(appt.doctor.name) • \(appt.doctor.specialty.rawValue) on \(formatted(appt.date))"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request, withCompletionHandler: nil)
        }
        
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                schedule()
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted { schedule() }
                }
            case .denied:
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
