import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel

    @State private var selectedProjectIndex: Int = 0
    @State private var showProjectInfo: Bool = false

    var body: some View {
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

                        NavigationLink(destination:
                            AllTaskView()
                                .environmentObject(taskViewModel)
                                .environmentObject(projectViewModel)
                        ) {
                            Text("All Task")
                                .font(.subheadline)
                                .foregroundColor(.gray)
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
                                        HStack {
                                            Image(systemName: "gamecontroller")
                                                .font(.title2)

                                            Spacer()

                                            Button(action: {
                                                showProjectInfo = true
                                            }) {
                                                Image(systemName: "info.circle")
                                                    .foregroundColor(.white)
                                            }
                                        }

                                        Text("Game Design")
                                            .font(.headline)

                                        Text("Create menu in dashboard & Make user flow")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)

                                        Text("25 Apr 2025")
                                            .font(.caption)
                                            .foregroundColor(.gray)

                                        Text("09:00 – 12:00")
                                            .font(.caption2)
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
                                           height: index == selectedProjectIndex ? 200 : 160)
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
            .sheet(isPresented: $showProjectInfo) {
                ProjectInfoSheetView(
                    title: "Game Design",
                    description: "Create menu in dashboard & Make user flow",
                    date: Date(),
                    startTime: Date(),
                    endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                )
                .presentationDetents([.height(220)])
                .presentationBackground(.clear)
            }
        }
    }


#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
}
