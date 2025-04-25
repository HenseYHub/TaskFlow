import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfileModel
    @State private var showPassword: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Profile")
                .font(.title)
                .bold()
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)

            Group {
                Text("Full Name")
                    .foregroundColor(.gray)
                TextField("Enter full name", text: $userProfile.fullName)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                Divider()

                Text("Profession")
                    .foregroundColor(.gray)
                TextField("Enter profession", text: $userProfile.profession)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                Divider()

                Text("Nickname")
                    .foregroundColor(.gray)
                TextField("Enter nickname", text: $userProfile.nickname)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                Divider()

                Text("E-mail")
                    .foregroundColor(.gray)
                TextField("Enter e-mail", text: $userProfile.email)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 8)
                    .keyboardType(.emailAddress)
                Divider()
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Button("Save") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .foregroundColor(.white)
    }
}

#Preview {
    EditProfileView(userProfile: UserProfileModel())
        .preferredColorScheme(.dark)
}

