import SwiftUI
import UserNotifications

struct LabTestBookingView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    let test: LabTest
    
    @State private var selectedDate: Date = Date()
    @State private var selectedTime: String? = nil
    @State private var showCalendar = false
    
    private let timeSlots: [String] = [
        "08:30 AM", "09:00 AM", "09:30 AM",
        "10:00 AM", "11:00 AM", "12:00 PM",
        "02:00 PM", "03:30 PM", "05:00 PM"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 10) {
                    Image(test.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(radius: 6)
                        .padding(.top, 24)
                    
                    Text(test.name)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(test.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(test.price)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
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
                
                Button {
                    bookLabTest()
                } label: {
                    Text("Book Lab Test")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTime != nil ? Color.blue : Color.gray,
                                    in: RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedTime == nil)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Book Lab Test")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCalendar) {
            VStack {
                DatePicker("Select date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                Button("Done") { showCalendar = false }
                    .padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    private func timeSlotChip(_ slot: String) -> some View {
        let isSelected = (selectedTime == slot)
        return Text(slot)
            .font(.subheadline.weight(.medium))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(isSelected ? Color.blue.opacity(0.25) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture { selectedTime = slot }
    }
    
    private func formatDate(_ date: Date) -> String {
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
    
    private func bookLabTest() {
        guard let selectedTime = selectedTime else { return }
        guard let finalDate = combine(date: selectedDate, time: selectedTime) else { return }
        
        let doctor = Doctor(name: "Lab Technician", specialty: .primaryCare, imageName: test.imageName)
        let appt = Appointment(
            doctor: doctor,
            date: finalDate,
            locationAddress: "Local Diagnostic Center",
            city: "Napoli",
            country: "Italia",
            status: .upcoming,
            image: test.imageName
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

#Preview {
    let sample = LabTest(name: "Complete Blood Count (CBC)",
                         description: "Measures red and white blood cells, hemoglobin, and platelets.",
                         price: "€25",
                         imageName: "lab1")
    NavigationStack {
        LabTestBookingView(test: sample)
            .environmentObject(HomeViewModel())
    }
}
