import SwiftUI
import UIKit

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var authVM: AuthViewModel   // ✅ нужен для UID + reset

    // Drafts
    @State private var nickname: String = ""
    @State private var profession: String = ""

    // Reset UI
    @State private var isSendingReset = false
    @State private var showResetAlert = false
    @State private var resetAlertTitleKey: String = ""
    @State private var resetAlertMessageKey: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerBar
                formCard
                resetPasswordButton   // ✅ добавили кнопку
                Spacer(minLength: 8)
            }
            .background(AppColorPalette.background.ignoresSafeArea())
            .onAppear(perform: loadDraft)
            .onChange(of: authVM.userId) { _, _ in
                loadDraft()
            }
            // ✅ алерт через LocalizedStringKey, чтобы не было StaticString ошибок
            .alert(LocalizedStringKey(resetAlertTitleKey), isPresented: $showResetAlert) {
                Button(LocalizedStringKey("ok")) { }
            } message: {
                Text(LocalizedStringKey(resetAlertMessageKey))
            }
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

                fieldRow(title: "Nickname", icon: "at", text: $nickname, autocap: .never)
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
            .padding(.top, 6)
        }
    }

    private var resetPasswordButton: some View {
        Button {
            sendResetPassword()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.rotation")
                    .frame(width: 22)
                    .foregroundColor(.white.opacity(0.85))

                Text(isSendingReset ? "reset_password_sending" : "reset_password_button")
                    .foregroundColor(.white)

                Spacer()

                if isSendingReset {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .disabled(isSendingReset)
        .padding(.top, 2)
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
                .textContentType(textContentType)
                .textInputAutocapitalization(autocap)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Save logic

    private var isSaveDisabled: Bool {
        [nickname, profession].allSatisfy { $0.trimmed().isEmpty }
    }

    private var uid: String? { authVM.userId }
    private func nicknameKey(_ uid: String) -> String { "profileNickname_\(uid)" }
    private func professionKey(_ uid: String) -> String { "profileProfession_\(uid)" }

    private func loadDraft() {
        guard let uid else {
            nickname = ""
            profession = ""
            userProfile.profile = nil
            return
        }

        let savedNick = UserDefaults.standard.string(forKey: nicknameKey(uid)) ?? ""
        let savedProf = UserDefaults.standard.string(forKey: professionKey(uid)) ?? ""

        nickname = savedNick
        profession = savedProf

        let existing = userProfile.profile
        userProfile.profile = UserProfile(
            id: existing?.id ?? uid,
            fullName: existing?.fullName ?? "",
            nickname: savedNick,
            profession: savedProf,
            email: existing?.email ?? "",
            avatarJPEGData: existing?.avatarJPEGData
        )
    }

    private func saveAndClose() {
        guard let uid else { return }

        let nick = nickname.trimmed()
        let prof = profession.trimmed()

        UserDefaults.standard.set(nick, forKey: nicknameKey(uid))
        UserDefaults.standard.set(prof, forKey: professionKey(uid))

        let existing = userProfile.profile
        userProfile.profile = UserProfile(
            id: existing?.id ?? uid,
            fullName: existing?.fullName ?? "",
            nickname: nick,
            profession: prof,
            email: existing?.email ?? "",
            avatarJPEGData: existing?.avatarJPEGData
        )

        dismiss()
    }

    // MARK: - Reset password

    private func sendResetPassword() {
        guard !isSendingReset else { return }
        isSendingReset = true

        authVM.sendPasswordReset { ok, messageKey in
            DispatchQueue.main.async {
                self.isSendingReset = false

                if ok {
                    self.resetAlertTitleKey = "reset_password_sent_title"
                    self.resetAlertMessageKey = messageKey ?? "reset_password_sent_message"
                } else {
                    self.resetAlertTitleKey = "reset_password_error_title"
                    self.resetAlertMessageKey = messageKey ?? "reset_password_error_generic"
                }

                self.showResetAlert = true
            }
        }
    }
}

// MARK: - Helper
private extension String {
    func trimmed() -> String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview {
    EditProfileSheet()
        .environmentObject(UserProfileModel())
        .environmentObject(AuthViewModel())
}
