import SwiftUI

struct SettingsView: View {
    @AppStorage("enableDarkMode") private var enableDarkMode = false
    @State private var useBiometrics = true
    @State private var sendUsageData = false
    @State private var enableSounds = true
    @State private var enableHaptics = true
    
    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Toggle("Dark Mode", isOn: $enableDarkMode)
            }
            Section(header: Text("Security")) {
                Toggle("Use Face ID / Touch ID", isOn: $useBiometrics)
            }
            Section(header: Text("Notifications")) {
                Toggle("Sounds", isOn: $enableSounds)
                Toggle("Haptics", isOn: $enableHaptics)
                NavigationLink("Manage notification types") { NotificationsView() }
            }
            Section(header: Text("Privacy")) {
                Toggle("Share anonymous usage data", isOn: $sendUsageData)
                NavigationLink("App Privacy Report") { PrivacyReportView() }
            }
            Section {
                NavigationLink("About") { AboutView() }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About screen
private struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)
                .padding(.top, 20)
            Text("FoundationApplication")
                .font(.title3.bold())
            Text("Version 1.0")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy report placeholder
private struct PrivacyReportView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("App Privacy Report")
                    .font(.headline)
                Text("Here you can show analytics on data access, network activity, and permissions usage. This is a placeholder you can replace later.")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .navigationTitle("Privacy Report")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
