import SwiftUI
import PhotosUI

struct SignUpView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("user_fullName") private var fullName: String = ""
    @AppStorage("user_email") private var email: String = ""
    @AppStorage("user_phone") private var phone: String = ""
    @AppStorage("user_address") private var address: String = ""
    
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @FocusState private var focused: Field?
    
    // Image picking
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    
    enum Field { case name, email, password, confirm, phone, address }
    
    var body: some View {
        Form {
            Section(header: Text("Profile Image")) {
                HStack(spacing: 12) {
                    Group {
                        if let img = pickedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(Color(.systemGray6))
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    
                    PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                        Label("Choose Image", systemImage: "photo.on.rectangle")
                    }
                }
            }
            
            Section(header: Text("Profile")) {
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
                    .focused($focused, equals: .name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                    .focused($focused, equals: .email)
                TextField("Phone (optional)", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focused, equals: .phone)
                TextField("Address (optional)", text: $address)
                    .textContentType(.fullStreetAddress)
                    .focused($focused, equals: .address)
            }
            Section(header: Text("Security")) {
                SecureField("Password (min 6 chars)", text: $password)
                    .textContentType(.newPassword)
                    .focused($focused, equals: .password)
                SecureField("Confirm password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focused, equals: .confirm)
            }
            Section {
                Button {
                    Task {
                        guard password == confirmPassword else {
                            await setError("Passwords do not match.")
                            return
                        }
                        await auth.signUp(
                            fullName: fullName,
                            email: email,
                            password: password,
                            phone: phone.isEmpty ? nil : phone,
                            address: address.isEmpty ? nil : address,
                            pickedImage: pickedImage
                        )
                        if auth.isAuthenticated {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if auth.isBusy { ProgressView() }
                        Text("Create Account").bold()
                    }
                }
                .disabled(auth.isBusy)
            }
            if let err = auth.errorMessage {
                Section {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pickedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    pickedImage = img
                } else {
                    pickedImage = nil
                }
            }
        }
    }
    
    @MainActor
    private func setError(_ message: String) {
        auth.errorMessage = message
    }
}
