import SwiftUI
import UIKit // для UIImagePickerController

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectVM: ProjectViewModel


    // Аватар (persist)
    @State private var profileImage: UIImage?
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var isShowingImagePicker = false

    // Навигация/состояния
    @State private var isEditingProfile = false
    @State private var showChangePasswordSheet = false
    @State private var showProgressHeatmap = false
    @State private var showLogoutAlert = false

    var body: some View {
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
        // экран редактирования профиля
        .sheet(isPresented: $isEditingProfile) {
            EditProfileSheet()
                .environmentObject(userProfile)
                .presentationDetents([.fraction(0.5), .large])        // не на весь экран
                .presentationDragIndicator(.visible)                    // «черточка»
                .presentationCornerRadius(24)
                .background(AppColorPalette.background.ignoresSafeArea())
        }

        // лист смены пароля
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordSheet()
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
        // пикер аватара
        .sheet(isPresented: $isShowingImagePicker) {
            LegacyImagePicker(image: $profileImage)
                .ignoresSafeArea()
        }
        .onAppear { loadSavedAvatar() }
        .onChange(of: isShowingImagePicker, initial: false) { _, isOpen in
            if !isOpen { saveAvatarIfNeeded() }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Spacer()
            Text("Profile")
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
                    .padding(24)
            }
        }
        .frame(width: 120, height: 120)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 1))
        .onTapGesture { isShowingImagePicker = true }
        .accessibilityLabel("Avatar")
    }

    @ViewBuilder
    private func nameRoleView() -> some View {
        let p = userProfile.profile
        // ник -> фуллнейм -> тире
        let displayName = (p?.nickname.isEmpty == false ? (p?.nickname ?? "")
                          : (p?.fullName ?? "—"))
        VStack(spacing: 4) {
            Text(displayName)
                .font(.title.bold())
                .foregroundColor(.white)
            Text(p?.profession ?? "")
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func statsView() -> some View {
        let completed = taskVM.tasks.filter { $0.isCompleted }.count

        HStack {
            VStack {
                Text("\(completed)")
                    .font(.title2.bold())
                    .foregroundColor(.blue)
                Text("Task Completed")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private func optionsView() -> some View {
        VStack(spacing: 10) {
            Button { isEditingProfile = true } label: {
                ProfileRow(icon: "person.circle", title: "My Account")
            }

            Button { showChangePasswordSheet = true } label: {
                ProfileRow(icon: "lock.circle", title: "Change Password")
            }

            Button { showProgressHeatmap = true } label: {
                ProfileRow(icon: "chart.bar", title: "My Progress")
            }
            .fullScreenCover(isPresented: $showProgressHeatmap) {
                ProgressHeatmapView()
                    .environmentObject(taskVM)
                    .environmentObject(projectVM)
            }

            Button { showLogoutAlert = true } label: {
                ProfileRow(icon: "arrow.left.circle", title: "Log Out", color: .red)
            }
            .alert("Are you sure you want to log out?", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) { authVM.signOut() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - Avatar persist

    private func loadSavedAvatar() {
        guard let data = profileImageData, let img = UIImage(data: data) else { return }
        profileImage = img
    }

    private func saveAvatarIfNeeded() {
        guard let img = profileImage,
              let data = img.jpegData(compressionQuality: 0.9) else { return }
        profileImageData = data
    }
}

// MARK: - UIKit picker (стабильный способ)

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

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            let edited = info[.editedImage] as? UIImage
            let original = info[.originalImage] as? UIImage
            if let uiImg = edited ?? original {
                parent.image = uiImg
            }
            parent.dismiss()
        }
    }
}

// MARK: - Row

struct ProfileRow: View {
    var icon: String
    var title: String
    var color: Color = .blue

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .padding(10)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 15))

            Text(title)
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
