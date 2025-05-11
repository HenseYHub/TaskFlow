import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfileModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Заголовок
            Text("Edit Profile")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            // Поля
            Group {
                ProfileInputField(title: "Full Name", text: $userProfile.fullName)
                ProfileInputField(title: "Profession", text: $userProfile.profession)
                ProfileInputField(title: "Nickname", text: $userProfile.nickname)
                ProfileInputField(title: "E-mail", text: $userProfile.email, keyboardType: .emailAddress)
            }

            Spacer()

            // Кнопки
            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Save") {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppColorPalette.background.ignoresSafeArea())
    }
}

// MARK: - Custom Input Field
struct ProfileInputField: View {
    var title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.gray)
                .font(.caption)

            TextField("Enter \(title.lowercased())", text: $text)
                .keyboardType(keyboardType)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    EditProfileView(userProfile: UserProfileModel())
        .environmentObject(UserProfileModel())
        .preferredColorScheme(.dark)
}
