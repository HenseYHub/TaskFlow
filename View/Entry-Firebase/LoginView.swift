import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authVM: AuthViewModel
    @State private var loginError: String? = nil
    @State private var showPassword = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .foregroundStyle(.linearGradient(colors: [.indigo, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing))
                .frame(width: 1000, height: 400)
                .rotationEffect(.degrees(135))
                .offset(y: -350)

            VStack(spacing: 20) {
                Text("Welcome to TaskFlow!")
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .offset(x: 5, y: -180)
                
                Text("Login to your Account")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .offset(x: -70, y: -40)

                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("Email")
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .frame(height: 44)
                    }
                    
                    TextField("", text: $email)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )

                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text("Password")
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .frame(height: 44)
                    }
                    
                    HStack {
                        if showPassword {
                            TextField("", text: $password)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                        } else {
                            SecureField("", text: $password)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(12)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                
                Button(action: {
                    guard !email.isEmpty else {
                        loginError = "Введите email для сброса пароля"
                        return
                    }
                    
                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                        if let error = error {
                            loginError = "Ошибка: \(error.localizedDescription)"
                        } else {
                            loginError = "Письмо для сброса пароля отправлено на \(email)"
                        }
                        }
                }) {
                    Text("Forgot Password")
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                Button {
                    authVM.signIn(email: email, password: password) { success, errorMessage in
                        if !success {
                            loginError = errorMessage
                        }
                    }
                } label: {
                    Text("Log In")
                        .bold()
                        .frame(width: 200, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.linearGradient(colors: [.indigo, .blue],
                                                      startPoint: .top,
                                                      endPoint: .bottomTrailing))
                        )
                        .foregroundColor(.white)
                }
                .padding(.top)
                .offset(y: 50)
                
                if let error = loginError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.top, -55)
                }
                
                //SignUpView
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.white)
                    
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign In")
                            .foregroundColor(.blue)
                            .bold()
                    }
                }
                .padding(.top)
                .offset(y: 50)
            }
            .frame(width: 350)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView()
                .environmentObject(AuthViewModel())
        }
    }
}
