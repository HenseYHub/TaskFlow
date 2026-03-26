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
                Text(LocalizedStringKey("login_title"))
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, -180)

                Text(LocalizedStringKey("login_subtitle"))
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .padding(.top, -40)

                // Email
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text(LocalizedStringKey("login_email_placeholder"))
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                            .frame(height: 44)
                    }

                    TextField("", text: $email)
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .padding(12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )

                // Password
                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text(LocalizedStringKey("login_password_placeholder"))
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
                                .textContentType(.password)
                                .padding(12)
                        } else {
                            SecureField("", text: $password)
                                .foregroundColor(.white)
                                .textInputAutocapitalization(.none)
                                .disableAutocorrection(true)
                                .textContentType(.password)
                                .padding(12)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.white.opacity(0.7))
                                .accessibilityLabel(
                                    LocalizedStringKey(showPassword ? "login_hide_password" : "login_show_password")
                                )
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )

                // Forgot password
                Button {
                    guard !email.isEmpty else {
                        loginError = String(localized: "login_reset_need_email",
                                            defaultValue: "Enter email to reset password")
                        return
                    }

                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                        if let error = error {
                            
                            let format = String(localized: "login_error_format", defaultValue: "Error: %@")
                            loginError = String(format: format, error.localizedDescription)
                        } else {
                            
                            let format = String(localized: "login_reset_sent_format",
                                                defaultValue: "Reset email sent to %@")
                            loginError = String(format: format, email)
                        }
                    }
                } label: {
                    Text(LocalizedStringKey("login_forgot_password"))
                        .foregroundColor(.blue)
                        .font(.footnote)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                // Log in
                Button {
                    authVM.signIn(email: email, password: password) { success, errorMessage in
                        if !success {
                            // Если errorMessage уже локализованный — оставляем как есть.
                            // Иначе можно сделать fallback ключом:
                            loginError = errorMessage ?? String(localized: "login_unknown_error",
                                                                defaultValue: "Something went wrong")
                        }
                    }
                } label: {
                    Text(LocalizedStringKey("login_button"))
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

                // Sign up
                HStack {
                    Text(LocalizedStringKey("login_no_account"))
                        .foregroundColor(.white)

                    NavigationLink(destination: SignUpView()) {
                        Text(LocalizedStringKey("login_sign_up"))
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
