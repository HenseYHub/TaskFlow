import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel

    @State private var tapCount = 0
    @State private var showEditProjectSheet: Bool = false
    @State private var selectedProjectIndex: Int = 0
    @State private var showProjectInfo: Bool = false
    
    @State private var editTitle = "Game Design"
    @State private var editDescription = "Create menu in dashboard & Make user flow"
    @State private var editComment = "Main project screen"
    @State private var editDate = Date()
    @State private var editStartTime = Date()
    @State private var editEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: Header
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

                // MARK: Project Section
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
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<5, id: \.self) { index in
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
                                        tapCount += 1
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            if tapCount == 1 {
                                                withAnimation {
                                                    selectedProjectIndex = index
                                                    scrollProxy.scrollTo(index, anchor: .center)
                                                }
                                            } else if tapCount == 2 {
                                                showEditProjectSheet = true
                                            }
                                            tapCount = 0
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // MARK: Tasks Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Tasks")
                            .font(.title2.bold())
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            // View all action
                        }) {
                            Text("View all")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)

                    ForEach(taskViewModel.tasks.prefix(3)) { task in
                        HStack {
                            Button(action: {
                                taskViewModel.toggleTaskCompletion(task: task)
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                    .foregroundColor(task.isCompleted ? .blue : .gray)
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .strikethrough(task.isCompleted, color: .gray)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
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
        .sheet(isPresented: $showEditProjectSheet) {
            ProjectEditSheetView(
                isPresented: $showEditProjectSheet,
                title: $editTitle,
                description: $editDescription,
                comment: $editComment,
                date: $editDate,
                startTime: $editStartTime,
                endTime: $editEndTime,
                projectIndex: selectedProjectIndex
            )
            .environmentObject(projectViewModel)
            .presentationDetents([.medium])
            .presentationBackground(.regularMaterial)
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
}
