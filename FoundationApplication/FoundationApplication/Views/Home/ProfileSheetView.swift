import SwiftUI

struct ProfileSheetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var auth: AuthViewModel

    @AppStorage("user_fullName") private var fullName: String = "Arshia"
    @AppStorage("user_email") private var email: String = "arshia@example.com"

    @State private var presentLogin: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Header
            HStack(spacing: 12) {
                Group {
                    if auth.isAuthenticated {
                        if let ui = auth.decodedProfileImage() {
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFill()
                        } else if UIImage(named: "ProfilePic") != nil {
                            Image("ProfilePic")
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.secondary)
                                .padding(6)
                                .background(Color(.systemGray6))
                        }
                    } else {
                        // Signed out: always show a neutral placeholder
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.secondary)
                            .padding(6)
                            .background(Color(.systemGray6))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(auth.isAuthenticated ? fullName : "Welcome")
                        .font(.title3.bold())
                    Text(auth.isAuthenticated ? "View and manage your profile" : "Please sign in to manage your profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if auth.isAuthenticated {
                        Text(email)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding(.horizontal)

            List {
                if auth.isAuthenticated {
                    Section {
                        NavigationLink {
                            PersonalDetailsView()
                                .environmentObject(viewModel)
                        } label: {
                            Label("Personal details", systemImage: "person.text.rectangle")
                                .foregroundColor(.blue)
                        }

                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                                .foregroundColor(.orange)
                        }

                        NavigationLink {
                            NotificationsView()
                        } label: {
                            Label("Notifications", systemImage: "bell")
                                .foregroundColor(.purple)
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            auth.signOut()
                            dismiss()
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }
                } else {
                    Section {
                        Button {
                            presentLogin = true
                        } label: {
                            Label("Sign in", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    }

                    Section {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gearshape")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .presentationDetents([.fraction(0.55), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            viewModel.reloadUserProfileFromStorage()
        }
        .sheet(isPresented: $presentLogin, onDismiss: {
            if auth.isAuthenticated {
                viewModel.reloadUserProfileFromStorage()
            }
        }) {
            NavigationStack {
                LoginView()
                    .environmentObject(auth)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ProfileSheetView()
        .environmentObject(HomeViewModel())
        .environmentObject(AuthViewModel())
}
