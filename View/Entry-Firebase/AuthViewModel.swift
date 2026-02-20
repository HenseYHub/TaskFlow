import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoginMode = true

    // ✅ важное
    @Published var userId: String? = nil

    private let db = Firestore.firestore()
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        // ✅ слушаем смену пользователя всегда
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.userId = user?.uid
            self.isSignedIn = (user?.isEmailVerified ?? false)
        }
    }

    deinit {
        if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) }
    }

    // Вход
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                print("Ошибка входа: \(error.localizedDescription)")
                completion(false, "Неверный email или пароль")
                return
            }

            guard let user = Auth.auth().currentUser else {
                completion(false, "Не удалось получить пользователя")
                return
            }

            if user.isEmailVerified {
                DispatchQueue.main.async {
                    self?.isSignedIn = true
                    self?.userId = user.uid
                    completion(true, nil)
                }
            } else {
                print("Email не подтвержден")
                try? Auth.auth().signOut()
                DispatchQueue.main.async {
                    self?.isSignedIn = false
                    self?.userId = nil
                }
                completion(false, "Подтвердите email перед входом")
            }
        }
    }
   
    // MARK: - Password reset

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


    // Регистрация
    func register(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Ошибка регистрации: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let user = result?.user else {
                completion(false)
                return
            }

            user.sendEmailVerification { error in
                if let error = error {
                    print("Ошибка при отправке письма: \(error.localizedDescription)")
                } else {
                    print("Письмо отправлено на \(email)")
                }
            }

            self?.db.collection("users").document(user.uid).setData([
                "email": email,
                "createdAt": Timestamp(),
                "uid": user.uid
            ]) { error in
                if let error = error {
                    print("Ошибка сохранения данных: \(error.localizedDescription)")
                } else {
                    print("Данные пользователя сохранены в Firestore")
                }
            }

            // Не входим
            try? Auth.auth().signOut()
            DispatchQueue.main.async {
                self?.isSignedIn = false
                self?.userId = nil
            }
            completion(true)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
            self.userId = nil
        } catch {
            print("Ошибка выхода: \(error.localizedDescription)")
        }
    }

    func switchToLogin() { isLoginMode = true }
    func switchToSignUp() { isLoginMode = false }
}
