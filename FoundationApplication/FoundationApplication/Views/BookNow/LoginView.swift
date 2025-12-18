import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @FocusState private var focused: Field?
    
    @State private var showSignUp = false
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                form
                signInButton
                createAccountButton
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpView()
                    .environmentObject(auth) // Ensure SignUpView can call auth.signUp(...)
            }
            .presentationDetents([.large])
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthed in
            // If this view is presented as a sheet (from booking), close it on success.
            if isAuthed {
                dismiss()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)
            Text("Welcome back")
                .font(.title2.bold())
            Text("Sign in to continue")
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var form: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit { focused = .password }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { Task { await auth.signIn(email: email, password: password) } }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var signInButton: some View {
        Button {
            Task { await auth.signIn(email: email, password: password) }
        } label: {
            HStack {
                if auth.isBusy {
                    ProgressView().tint(.white)
                }
                Text("Sign In").bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.blue, in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(auth.isBusy)
        .padding(.top, 6)
    }
    
    private var createAccountButton: some View {
        Button {
            showSignUp = true
        } label: {
            Text("Don’t have an account? Create one")
                .font(.footnote)
        }
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
