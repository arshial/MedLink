import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    // Authentication state
    @AppStorage("auth_isAuthenticated") private var storedAuth: Bool = false
    @Published var isAuthenticated: Bool = false

    // Stored credentials (demo only; consider Keychain in production)
    @AppStorage("auth_savedEmail") private var savedEmail: String = ""
    @AppStorage("auth_savedPassword") private var savedPassword: String = ""

    // Base64 profile image storage
    @AppStorage("user_imageBase64") private var imageBase64: String = ""
    @AppStorage("user_hasCustomImage") private var hasCustomImage: Bool = false

    @Published var isBusy: Bool = false
    @Published var errorMessage: String?

    // 🔹 ADD this property
    // PURPOSE: Notify HomeViewModel to refresh user data after auth
    weak var homeViewModel: HomeViewModel?

    // 1️⃣ Make stored auth the single source of truth
    init() {
        self.isAuthenticated = storedAuth
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        try? await Task.sleep(nanoseconds: 300_000_000)

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !e.isEmpty, !p.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        guard e.contains("@") else {
            errorMessage = "Please enter a valid email."
            return
        }
        guard !savedEmail.isEmpty, !savedPassword.isEmpty else {
            errorMessage = "No account found. Please create one."
            return
        }
        guard e.caseInsensitiveCompare(savedEmail) == .orderedSame, p == savedPassword else {
            errorMessage = "Email or password is incorrect."
            return
        }

        // 🔹 MODIFY signIn(...) — ADD these lines at the END of success
        storedAuth = true
        isAuthenticated = true

        // 🔻 ADD THIS
        homeViewModel?.onUserAuthenticated()
    }

    // 🔹 OPTIONAL BUT RECOMMENDED
    // PURPOSE: Clear runtime-only errors on sign out
    func signOut() {
        storedAuth = false
        isAuthenticated = false
        errorMessage = nil
        // Keep saved credentials and profile so user can log in again.
    }

    // 3️⃣ Ensure profile image propagates everywhere after signup
    func signUp(
        fullName: String,
        email: String,
        password: String,
        phone: String?,
        address: String?,
        pickedImage: UIImage?
    ) async {
        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        try? await Task.sleep(nanoseconds: 300_000_000)

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !fullName.isEmpty else {
            errorMessage = "Please enter your full name."
            return
        }
        guard e.contains("@") else {
            errorMessage = "Please enter a valid email."
            return
        }
        guard p.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        savedEmail = e
        savedPassword = p

        UserDefaults.standard.set(fullName, forKey: "user_fullName")
        UserDefaults.standard.set(e, forKey: "user_email")
        if let phone { UserDefaults.standard.set(phone, forKey: "user_phone") }
        if let address { UserDefaults.standard.set(address, forKey: "user_address") }

        if let img = pickedImage,
           let data = img.jpegData(compressionQuality: 0.9) {
            imageBase64 = data.base64EncodedString()
            hasCustomImage = true
            UserDefaults.standard.set("__custom_profile_image__", forKey: "user_imageName")
        }

        // 🔹 MODIFY signUp(...) — ADD these lines at the END of success
        storedAuth = true
        isAuthenticated = true
        objectWillChange.send()

        // 🔻 ADD THIS
        homeViewModel?.onUserAuthenticated()
    }

    // 2️⃣ Force UI refresh when profile image changes
    func decodedProfileImage() -> UIImage? {
        guard hasCustomImage,
              !imageBase64.isEmpty,
              let data = Data(base64Encoded: imageBase64),
              let img = UIImage(data: data)
        else { return nil }

        return img
    }
}
