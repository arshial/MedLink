import SwiftUI

struct PersonalDetailsView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    
    // Persisted user details (shared keys)
    @AppStorage("user_fullName") private var fullName: String = "Arshia"
    @AppStorage("user_email") private var email: String = "arshia@example.com"
    @AppStorage("user_phone") private var phone: String = "+39 333 123 4567"
    @AppStorage("user_address") private var address: String = "Via Roma 12, Napoli, Italia"
    
    @FocusState private var focusedField: Field?
    @State private var showSavedAlert = false
    
    enum Field: Hashable {
        case name, email, phone, address
    }
    
    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.gray)
                    VStack(alignment: .leading) {
                        Text(fullName).font(.headline)
                        Text(email).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Edit details")) {
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.done)
                
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focusedField, equals: .phone)
                    .submitLabel(.done)
                
                TextField("Address", text: $address)
                    .textContentType(.fullStreetAddress)
                    .focused($focusedField, equals: .address)
                    .submitLabel(.done)
            }
        }
        .navigationTitle("Personal details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveAndDismissKeyboard()
                }
                .bold()
            }
        }
        .alert("Saved", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your personal details have been updated.")
        }
    }
    
    private func saveAndDismissKeyboard() {
        focusedField = nil
        
        // Write back to the view model
        var updated = viewModel.userProfile
        updated.fullName = fullName
        updated.email = email
        updated.phone = phone
        updated.address = address
        viewModel.userProfile = updated
        
        showSavedAlert = true
    }
}


