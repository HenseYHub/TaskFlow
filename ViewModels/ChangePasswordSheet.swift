import SwiftUI

struct ChangePasswordSheet: View {
    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @State private var showCurrentPassword: Bool = false
    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Change Password")
                .font(.title2.bold())
                .foregroundColor(.white)

            VStack(spacing: 16) {
                passwordField(
                    title: "Current Password",
                    text: $currentPassword,
                    isSecure: !showCurrentPassword,
                    toggleVisibility: { showCurrentPassword.toggle() },
                    isVisible: showCurrentPassword
                )

                passwordField(
                    title: "New Password",
                    text: $newPassword,
                    isSecure: !showNewPassword,
                    toggleVisibility: { showNewPassword.toggle() },
                    isVisible: showNewPassword
                )

                passwordField(
                    title: "Confirm New Password",
                    text: $confirmPassword,
                    isSecure: !showConfirmPassword,
                    toggleVisibility: { showConfirmPassword.toggle() },
                    isVisible: showConfirmPassword
                )
            }

            Button(action: {
                // handle save action
            }) {
                Text("Save")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top)

            Spacer()
        }
        .padding()
        .background(AppColorPalette.background.ignoresSafeArea())
    }

    @ViewBuilder
    func passwordField(title: String, text: Binding<String>, isSecure: Bool, toggleVisibility: @escaping () -> Void, isVisible: Bool) -> some View {
        HStack {
            if isSecure {
                SecureField("", text: text, prompt: Text(title).foregroundColor(.white.opacity(0.7)))
                    .foregroundColor(.white)
            } else {
                TextField("", text: text, prompt: Text(title).foregroundColor(.white.opacity(0.7)))
                    .foregroundColor(.white)
            }

            Button(action: toggleVisibility) {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}


#Preview {
    ChangePasswordSheet()
}
