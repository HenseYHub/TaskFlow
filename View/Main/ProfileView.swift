import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectVM: ProjectViewModel

    // ✅ Avatar stored per UID
    @State private var profileImage: UIImage?
    @State private var isShowingImagePicker = false

    // UI state
    @State private var isEditingProfile = false
    @State private var showChangePasswordSheet = false
    @State private var showProgressHeatmap = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                AppColorPalette.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerView()
                        avatarView()
                        nameRoleView()
                        statsView()
                        optionsView()
                            .padding(.top)
                            .padding(.bottom, 80)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileSheet()
                    .environmentObject(userProfile)
                    .environmentObject(authVM)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
                    .presentationCornerRadius(24)
            }
            .sheet(isPresented: $showChangePasswordSheet) {
                ChangePasswordSheet()
                    .presentationDetents([.height(420)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingImagePicker) {
                LegacyImagePicker(image: $profileImage)
                    .ignoresSafeArea()
            }
            .onAppear { reloadForCurrentUser() }
            .onChange(of: authVM.userId) { _, _ in
                reloadForCurrentUser()
            }
            .onChange(of: isShowingImagePicker, initial: false) { _, isOpen in
                if !isOpen { saveAvatarIfNeeded() }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Spacer()
            Text("profile_title")
                .font(.title2.bold())
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func avatarView() -> some View {
        Group {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.crop.square.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(20)
            }
        }
        .frame(width: 120, height: 120)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .onTapGesture { isShowingImagePicker = true }
        .accessibilityLabel(Text("avatar_accessibility"))
    }

    @ViewBuilder
    private func nameRoleView() -> some View {
        let nick = (loadNickname() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        
        let displayName = nick.isEmpty ? "—" : nick

        VStack(spacing: 4) {
            Text(displayName)
                .font(.title.bold())
                .foregroundColor(.white)

            Text(userProfile.profile?.profession ?? "")
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func statsView() -> some View {
        let completed = taskVM.tasks.filter { $0.isCompleted }.count

        HStack {
            VStack(spacing: 2) {
                Spacer(minLength: 6)

                Text("\(completed)")
                    .font(.title2.bold())
                    .foregroundColor(.blue)

                Text("task_completed")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .padding(.horizontal, 4)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func optionsView() -> some View {
        VStack(spacing: 10) {
            Button { isEditingProfile = true } label: {
                ProfileRow(icon: "person.circle", titleKey: "my_account")
            }

            NavigationLink {
                AllTasksView()
                    .environmentObject(taskVM)
                    .environmentObject(projectVM)
            } label: {
                ProfileRow(icon: "checklist.checked", titleKey: "all_tasks")
            }

            Button { showProgressHeatmap = true } label: {
                ProfileRow(icon: "chart.bar", titleKey: "my_progress")
            }
            .fullScreenCover(isPresented: $showProgressHeatmap) {
                ProgressHeatmapView()
                    .environmentObject(taskVM)
                    .environmentObject(projectVM)
            }

            Button { showLogoutAlert = true } label: {
                ProfileRow(icon: "arrow.left.circle", titleKey: "log_out", color: .red)
            }
            .alert("logout_confirm_title", isPresented: $showLogoutAlert) {
                Button(String(localized: "log_out"), role: .destructive) { authVM.signOut() }
                Button(String(localized: "cancel"), role: .cancel) { }
            }
        }
    }

    // MARK: - Persist (per UID)

    private func currentUID() -> String? { authVM.userId }

    private func avatarKey(for uid: String) -> String { "profileImageData_\(uid)" }
    private func nicknameKey(for uid: String) -> String { "profileNickname_\(uid)" }

    private func reloadForCurrentUser() {
        profileImage = nil

        
        if let uid = currentUID() {
            userProfile.profile = UserProfile(
                id: uid,
                fullName: "",
                nickname: "",      
                profession: "",
                email: "",
                avatarJPEGData: nil
            )
        } else {
            userProfile.profile = nil
        }

        loadSavedAvatar()
    }

    private func loadSavedAvatar() {
        guard let uid = currentUID() else {
            profileImage = nil
            userProfile.profile?.avatarJPEGData = nil
            return
        }

        if let data = UserDefaults.standard.data(forKey: avatarKey(for: uid)),
           let img = UIImage(data: data) {
            profileImage = img
            userProfile.profile?.avatarJPEGData = data
            userProfile.objectWillChange.send()
        } else {
            profileImage = nil
            userProfile.profile?.avatarJPEGData = nil
            userProfile.objectWillChange.send()
        }
    }

    private func saveAvatarIfNeeded() {
        guard let uid = currentUID() else { return }
        guard let img = profileImage,
              let data = img.jpegData(compressionQuality: 0.9) else { return }

        UserDefaults.standard.set(data, forKey: avatarKey(for: uid))
        userProfile.profile?.avatarJPEGData = data
        userProfile.objectWillChange.send()
    }

    private func loadNickname() -> String? {
        guard let uid = currentUID() else { return nil }
        return UserDefaults.standard.string(forKey: nicknameKey(for: uid))
    }
}

// MARK: - UIKit picker

struct LegacyImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: LegacyImagePicker
        init(_ parent: LegacyImagePicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let edited = info[.editedImage] as? UIImage
            let original = info[.originalImage] as? UIImage
            if let uiImg = edited ?? original { parent.image = uiImg }
            parent.dismiss()
        }
    }
}

// MARK: - Row

struct ProfileRow: View {
    var icon: String
    var titleKey: LocalizedStringKey
    var color: Color = .blue

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(10)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(titleKey)
                .foregroundColor(color == .red ? .red : .white)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProfileView()
        .environmentObject(TaskViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
}
