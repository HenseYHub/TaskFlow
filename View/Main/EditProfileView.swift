import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfileModel

    // Редактируем только эти два поля
    @State private var nickname: String = ""
    @State private var profession: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Nickname", text: $nickname)
                    TextField("Your Dream Profession", text: $profession)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIntoModel()
                        dismiss()
                    }
                    .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadFromModel)
        }
    }

    // MARK: - Sync

    private func loadFromModel() {
        let p = userProfile.profile
        nickname   = p?.nickname   ?? ""
        profession = p?.profession ?? ""
    }

    private func saveIntoModel() {
        // Берём существующие значения fullName/email/аватар, чтобы не потерять
        let current = userProfile.profile
        let new = UserProfile(
            id: current?.id ?? UUID().uuidString,
            fullName: current?.fullName ?? "",             // сохраняем как было
            nickname: nickname,                             // обновляем
            profession: profession,                         // обновляем
            email: current?.email ?? "",                    // сохраняем как было
            avatarJPEGData: current?.avatarJPEGData         // сохраняем как было
        )
        userProfile.profile = new
    }
}

#if DEBUG
#Preview {
    let model = UserProfileModel()
    model.profile = UserProfile(
        id: "preview",
        fullName: "Pavlo Brodiuk",
        nickname: "pavlo.dev",
        profession: "iOS Dev",
        email: "pavlo.dev@example.com",
        avatarJPEGData: nil
    )
    return EditProfileView()
        .environmentObject(model)
        .preferredColorScheme(.dark)
}
#endif
