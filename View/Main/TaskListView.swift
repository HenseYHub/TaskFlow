import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @State private var selectedProjectIndex: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Верхняя карточка с фоном и приветом
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 220)
                    .overlay(
                        Image("waveBackground")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .scaleEffect(y: 1.5, anchor: .bottom)
                            .offset(y: -10)
                            .opacity(0.4)
                    )
                    .clipShape(RoundedCorner(radius: 40, corners: [.bottomLeft, .bottomRight]))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Привіт, \(userProfile.nickname.isEmpty ? "Користувач" : userProfile.nickname)!")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Text("Let's find your best project!")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal)
                    .padding(.top, 70)

                    HStack {
                        Spacer()
                        if let image = userProfile.avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.top, 70)
                    .padding(.trailing, 16)
                }

                // MARK: - Project Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Project")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Button("All Task") {
                            // переход ко всем задачам
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<5, id: \ .self) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Image(systemName: "gamecontroller")
                                            .font(.title2)

                                        Text("Game Design")
                                            .font(.headline)

                                        Text("Create menu in dashboard & Make user flow")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        if index == selectedProjectIndex {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(.black)
                                                    .padding(6)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(width: index == selectedProjectIndex ? 200 : 160,
                                           height: index == selectedProjectIndex ? 180 : 160)
                                    .background(index == selectedProjectIndex ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .id(index)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedProjectIndex = index
                                            scrollProxy.scrollTo(index, anchor: .center)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .background(AppColors.background.ignoresSafeArea())
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .environmentObject(UserProfileModel())
}
