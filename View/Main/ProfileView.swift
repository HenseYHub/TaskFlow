import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var taskVM: TaskViewModel
    @StateObject private var userProfile = UserProfileModel()
    @State private var profileImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isEditingProfile = false
    @State private var isShowingPasswordSheet = false
    @State private var showChangePasswordSheet = false
    @AppStorage("isLoggenIn") var isLoggedIn: Bool = true
    @State private var showProgressHeatmap = false

        
    var body: some View {
        ZStack(alignment: .top) {
            AppColorPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // Top bar
                    HStack {
                        Spacer()

                        Text("Profile")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Avatar
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white, lineWidth: 2))
                            .onTapGesture {
                                isShowingImagePicker = true
                            }
                    } else {
                        Image(systemName: "person.crop.square.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .frame(width: 120, height: 120)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .onTapGesture {
                                isShowingImagePicker = true
                            }
                    }

                    // Name & profession
                    Text(userProfile.fullName)
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Text(userProfile.profession)
                        .foregroundColor(.gray)

                    // Stats
                    HStack(spacing: 10) {
                        VStack {
                            Text("0") // Заменить позже
                                .font(.title2.bold())
                                .foregroundColor(.blue)
                            Text("Task Completed")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 140, height: 60)
                        .background(Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack {
                            Text("0") // Заменить позже
                                .font(.title2.bold())
                                .foregroundColor(.blue)
                            Text("Project Completed")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 140, height: 60)
                        .background(Color.gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Options
                    VStack(spacing: 10) {
                        Button {
                            isEditingProfile = true
                        } label: {
                            ProfileRow(icon: "person.circle", title: "My Account")
                        }


                        Button(action: {
                            showChangePasswordSheet = true
                        }) {
                            ProfileRow(icon: "lock.circle", title: "Change Password")
                        }

                        Button {
                            showProgressHeatmap = true
                        } label: {
                            ProfileRow(icon: "chart.bar", title: "My Progress")
                        }
                        .sheet(isPresented: $showProgressHeatmap, content: {
                            ProgressHeatmapView()
                                .environmentObject(taskVM)
                        })

                        Button {
                            isLoggedIn = false
                        } label: {
                            ProfileRow(icon: "arrow.left.circle", title: "Log Out", color: .red)
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 80)
                }
                .padding()
            }
        }
        .fullScreenCover(isPresented: $isEditingProfile) {
            EditProfileView(userProfile: userProfile)
                .background(AppColorPalette.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            ChangePasswordSheet()
                .presentationDetents([.height(380)]) // можно регулировать
                .presentationDragIndicator(.visible)
                .presentationDragIndicator(.hidden)
        }

    }
}

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
}
