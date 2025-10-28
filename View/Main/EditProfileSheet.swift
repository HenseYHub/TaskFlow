import SwiftUI
import UIKit

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfileModel
    @AppStorage("profileSetupComplete") private var profileSetupComplete = false

    // Локальные драфты
    @State private var nickname: String = ""
    @State private var profession: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerBar
                formCard
                Spacer(minLength: 8)
            }
            .background(AppColorPalette.background.ignoresSafeArea())
            .onAppear(perform: loadDraft)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text("Edit Profile")
                .font(.headline.bold())
                .foregroundColor(.white)

            Spacer()

            Button("Save") { saveAndClose() }
                .font(.headline)
                .foregroundColor(.white)
                .opacity(isSaveDisabled ? 0.4 : 1)
                .disabled(isSaveDisabled)
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Card

    private var formCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("PROFILE")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.horizontal, 4)

                fieldRow(title: "Nickname", icon: "at", text: $nickname)
                fieldRow(title: "Your Dream Profession", icon: "briefcase", text: $profession)
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top, ) // немного поднимаем карточку
        }
    }

    private func fieldRow(
        title: String,
        icon: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocap: TextInputAutocapitalization = .sentences
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundColor(.white.opacity(0.8))

            TextField(title, text: text)
                .keyboardType(keyboard)
                .textContentType(textContentType)     // nil допускается
                .textInputAutocapitalization(autocap)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Logic

    private var isSaveDisabled: Bool {
        // оба поля пустые — не сохраняем
        [nickname, profession].allSatisfy { $0.trimmed().isEmpty }
    }

    private func loadDraft() {
        if profileSetupComplete, let p = userProfile.profile {
            nickname   = p.nickname
            profession = p.profession
        } else {
            nickname = ""
            profession = ""
        }
    }

    private func saveAndClose() {
        let existing = userProfile.profile
        let updated = UserProfile(
            id: existing?.id ?? UUID().uuidString,
            fullName: existing?.fullName ?? "",
            nickname: nickname.trimmed(),
            profession: profession.trimmed(),
            email: existing?.email ?? "",
            avatarJPEGData: existing?.avatarJPEGData
        )
        userProfile.profile = updated
        profileSetupComplete = true
        dismiss()
    }
}

// MARK: - Small helper
private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview {
    EditProfileSheet()
        .environmentObject(UserProfileModel())
}
