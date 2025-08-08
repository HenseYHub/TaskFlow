import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoginMode = true
    
    private let db = Firestore.firestore()
    
    init() {
        self.isSignedIn = Auth.auth().currentUser?.isEmailVerified ?? false
    }
    
    // Вход
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
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
                    completion(true, nil)
                }
            } else {
                print("Email не подтвержден")
                try? Auth.auth().signOut()
                completion(false, "Подтвердите email перед входом")
            }
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
            
            // Отправка письма подтверждения
            user.sendEmailVerification { error in
                if let error = error {
                    print("Ошибка при отправке письма: \(error.localizedDescription)")
                } else {
                    print("Письмо отправлено на \(email)")
                    
                    self?.isSignedIn = false
                    completion(true)
                }
            }
            
            // Сохраняем данные в Firestore
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
            
            // Не входим, а возвращаем на LoginView
            try? Auth.auth().signOut()
            completion(true)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isSignedIn = false
        } catch {
            print("Ошибка выхода: \(error.localizedDescription)")
        }
    }
    
    func switchToLogin() { isLoginMode = true }
    func switchToSignUp() { isLoginMode = false }
}
