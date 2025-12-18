import SwiftUI

struct NotificationsView: View {
    @State private var appointmentReminders = true
    @State private var labResults = true
    @State private var messages = true
    @State private var promotions = false
    
    var body: some View {
        Form {
            Section(header: Text("Push notifications")) {
                Toggle("Appointment reminders", isOn: $appointmentReminders)
                Toggle("Lab results", isOn: $labResults)
                Toggle("Messages", isOn: $messages)
                Toggle("Promotions & tips", isOn: $promotions)
            }
            
            Section {
                NavigationLink("Notification settings help") {
                    NotificationHelpView()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Managing notifications")
                    .font(.headline)
                Text("Use the toggles to enable or disable different types of notifications. You can also manage system-level permissions in Settings > Notifications.")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
    }
}
