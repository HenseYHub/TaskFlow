import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userProfile = UserProfileModel()
    @State private var profileImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isEditingProfile = false
    @State private var selectedRow: String? = nil

    var body: some View {
        ZStack(alignment: .top) {
            AppColorPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // Top bar
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }

                        Spacer()

                        Text("Profile")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            isEditingProfile.toggle()
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
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
                            Text("257")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                            Text("Complete Task")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 60)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack {
                            Text("356")
                                .font(.title2.bold())
                                .foregroundColor(.blue)
                            Text("Pending Task")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(width: 120, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Options
                    VStack(spacing: 10) {
                        Button(action: {
                            selectedRow = "MyAccount"
                        }) {
                            ProfileRow(icon: "person.circle", title: "My Account")
                        }

                        Button(action: {
                            selectedRow = "ChangePassword"
                        }) {
                            ProfileRow(icon: "lock.circle", title: "Change Password")
                        }

                        Button(action: {
                            selectedRow = "Project"
                        }) {
                            ProfileRow(icon: "doc.text", title: "Project You Are In")
                        }

                        Button(action: {
                            // TODO: Handle log out
                        }) {
                            ProfileRow(icon: "arrow.left.circle", title: "Log Out", color: .red)
                        }

                    }
                    .padding(.top)
                    .padding(.bottom, 80) // <- чтобы не уезжала под TabBar
                }
                .padding()
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            EditProfileView(userProfile: userProfile)
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
}
