import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @EnvironmentObject var authVM: AuthViewModel

    @State private var showPasswordMismatch = false
    @State private var showVerificationAlert = false
    @State private var shakeOffset: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) var dismiss
    
    @State private var loginError: String?

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


            ScrollView {
                VStack(spacing: 20) {
                    Text("Create your Account")
                        .foregroundColor(.white)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .padding(.top, 10)
                        .offset(y: -50)

                    // Email field with placeholder
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("example@gmail.соm")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(.leading, 16)
                        }

                        TextField("", text: $email)
                            .padding(12)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .textInputAutocapitalization(.none)
                            .disableAutocorrection(true)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    }

                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                        }
                        HStack {
                            if showPassword {
                                TextField("", text: $password)
                                    .textContentType(.oneTimeCode)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .textInputAutocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else{
                                SecureField("", text: $password)
                                    .textContentType(.oneTimeCode)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .textInputAutocapitalization(.none)
                                    .disableAutocorrection(true)
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
                    
                    
                    ZStack(alignment: .leading) {
                        if confirmPassword.isEmpty {
                            Text("Confirm Password")
                                .foregroundColor(.white)
                                .padding(.leading, 16)
                                .frame(height: 44)
                                .alignmentGuide(.firstTextBaseline) { _ in 22 }
                                }
                        HStack {
                            if showConfirmPassword {
                                TextField("", text: $confirmPassword)
                                    .textContentType(.oneTimeCode)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .textInputAutocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("", text: $confirmPassword)
                                    .textContentType(.oneTimeCode)
                                    .padding(12)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .textInputAutocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash": "eye")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    // Password mismatch warning
                    if showPasswordMismatch {
                        Text("Passwords don’t match")
                            .foregroundColor(.red)
                            .bold()
                            .offset(x: shakeOffset)
                            .onAppear {
                                shakeText()
                            }
                            .padding(.top, -8)
                    }

                    // Sign up button
                    Button {
//                        if password != confirmPassword {
//                            showPasswordMismatch = true
//                            shakeText()
//                            return
//                        }
//                        
//                        showPasswordMismatch = false
//                        authVM.register(email: email, password: password) { success in
//                            if success {
//                                showVerificationAlert = true
//                            }
//                        }
                        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
                            loginError = "Все поля должны быть заполнены"
                            return
                        }
                        guard password.count >= 6 else {
                            loginError = "Пароль должен содердать минимум 6 символов"
                            return
                        }
                        guard password == confirmPassword else {
                            loginError = "Пароли не совпадают"
                            return
                        }
                        
                        loginError = nil
                        authVM.register(email: email, password: password) { success in
                            if success {
                                showVerificationAlert = true
                            }
                        }
                    } label: {
                        Text("Sign Up")
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
                    .alert(isPresented: $showVerificationAlert) {
                        Alert(
                            title: Text("Проверьте почту"),
                            message: Text("Мы отправили письмо для подтверждения регистрации на \(email). Подтвердите адрес, чтобы войти в приложение."),
                            dismissButton: .default(Text("OK")) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                    if let loginError = loginError {
                        Text(loginError)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    // Switch to login
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.white)
                        Button {
                            dismiss()
                        } label: {
                                Text("Sign In")
                                    .foregroundColor(.blue)
                                    .bold()
                        }
                    }
                    .padding(.top)

                    Spacer()
                }
                .frame(width: 350)
                .padding()
                .offset(y: 150)
            }
        }
    }

    // Shake animation
    func shakeText() {
        withAnimation(.default.repeatCount(3, autoreverses: true)) {
            shakeOffset = -10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            shakeOffset = 10
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            shakeOffset = 0
        }
    }
}


struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
