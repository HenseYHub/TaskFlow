import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoginMode = true

    // important
    @Published var userId: String? = nil

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        // listen for auth state changes
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.userId = user?.uid
            self.isSignedIn = (user?.isEmailVerified ?? false)
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                print("Sign-in error: \(error.localizedDescription)")
                completion(false, "Invalid email or password")
                return
            }

            guard let user = Auth.auth().currentUser else {
                completion(false, "Failed to retrieve user")
                return
            }

            if user.isEmailVerified {
                DispatchQueue.main.async {
                    self?.isSignedIn = true
                    self?.userId = user.uid
                    completion(true, nil)
                }
            } else {
                print("Email not verified")
                try? Auth.auth().signOut()
                DispatchQueue.main.async {
                    self?.isSignedIn = false
                    self?.userId = nil
                }
                completion(false, "Please verify your email before signing in")
            }
        }
    }
   
    // MARK: - Password Reset

    func sendPasswordReset(completion: @escaping (Bool, String?) -> Void) {
        guard let email = Auth.auth().currentUser?.email, !email.isEmpty else {
            completion(false, "reset_password_error_no_email")
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Password reset error: \(error.localizedDescription)")
                completion(false, "reset_password_error_generic")
                return
            }
            completion(true, "reset_password_sent_message")
        }
    }

    // MARK: - Register

    func register(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Registration error: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let user = result?.user else {
                completion(false)
                return
            }

            user.sendEmailVerification { error in
                if let error = error {
                    print("Error sending verification email: \(error.localizedDescription)")
                } else {
                    print("Verification email sent to \(email)")
                }
            }

            self?.db.collection("users").document(user.uid).setData([
                "email": email,
                "createdAt": Timestamp(),
                "uid": user.uid
            ]) { error in
                if let error = error {
                    print("Error saving user data: \(error.localizedDescription)")
                } else {
                    print("User data saved to Firestore")
                }
            }

            // Do not sign in automatically
            try? Auth.auth().signOut()
            DispatchQueue.main.async {
                self?.isSignedIn = false
                self?.userId = nil
            }
            completion(true)
        }
    }

    // MARK: - Sign Out

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.userId = nil
        } catch {
            print("Sign-out error: \(error.localizedDescription)")
        }
    }

    func switchToLogin() { isLoginMode = true }
    func switchToSignUp() { isLoginMode = false }
}
