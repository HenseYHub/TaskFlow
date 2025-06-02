import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectViewModel: ProjectViewModel

    @State private var tapCount = 0
    @State private var showEditProjectSheet: Bool = false
    @State private var selectedProjectIndex: Int = 0
    @State private var showProjectInfo: Bool = false

    @State private var editTitle = ""
    @State private var editDescription = ""
    @State private var editComment = ""
    @State private var editDate = Date()
    @State private var editStartTime = Date()
    @State private var editEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var editIsCompleted = false

    @State private var showCreateTaskView = false

    // Показываем первые 3 задачи из всех (без фильтра)
    var previewTasks: [TaskModel] {
        Array(taskViewModel.tasks.prefix(3))
    }

    var body: some View {
        NavigationStack {
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
                    if !projectViewModel.projects.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Projects")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                Spacer()

                                NavigationLink(destination:
                                    AllProjectsView()
                                        .environmentObject(projectViewModel)
                                        .environmentObject(taskViewModel)
                                ) {
                                    Text("All Projects")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)

                            ScrollViewReader { scrollProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(projectViewModel.projects.indices, id: \.self) { index in
                                            let project = projectViewModel.projects[index]
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Spacer()
                                                    Button(action: {
                                                        showProjectInfo = true
                                                    }) {
                                                        Image(systemName: "info.circle")
                                                            .foregroundColor(.white)
                                                    }
                                                }

                                                Text(project.title)
                                                    .font(.headline)

                                                Text(project.description)
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)

                                                Text(project.date.formatted(date: .abbreviated, time: .omitted))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)

                                                Text("\(formattedTime(project.startTime)) – \(formattedTime(project.endTime))")
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
                                                            projectViewModel.selectedProjectIndex = index
                                                            scrollProxy.scrollTo(index, anchor: .center)
                                                        }
                                                    } else if tapCount == 2 {
                                                        editTitle = project.title
                                                        editDescription = project.description
                                                        editComment = project.comment
                                                        editDate = project.date
                                                        editStartTime = project.startTime
                                                        editEndTime = project.endTime
                                                        editIsCompleted = false // если в ProjectModel есть isCompleted - замени
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
                    } else {
                        VStack(spacing: 16) {
                            Text("Ще не створено жодного проекту, але все попереду!")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            Button(action: {
                                showCreateTaskView = true
                            }) {
                                Text("Створити проект")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }

                    // MARK: Tasks Section (Показываем первые 3 задачи)
                    if !taskViewModel.tasks.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Tasks")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)

                                Spacer()

                                NavigationLink(destination:
                                    AllTaskView()
                                        .environmentObject(taskViewModel)
                                        .environmentObject(projectViewModel)
                                ) {
                                    Text("All Tasks")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)

                            ForEach(previewTasks) { task in
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
            }
            .background(AppColorPalette.background.ignoresSafeArea())
            .sheet(isPresented: $showProjectInfo) {
                if selectedProjectIndex < projectViewModel.projects.count {
                    let project = projectViewModel.projects[selectedProjectIndex]
                    ProjectInfoSheetView(
                        title: project.title,
                        description: project.description,
                        date: project.date,
                        startTime: project.startTime,
                        endTime: project.endTime
                    )
                    .presentationDetents([.height(220)])
                    .presentationBackground(.clear)
                }
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
                    isCompleted: $editIsCompleted,
                    projectIndex: selectedProjectIndex
                )
                .environmentObject(projectViewModel)
                .presentationDetents([.medium])
                .presentationBackground(.regularMaterial)
            }
            .fullScreenCover(isPresented: $showCreateTaskView) {
                CreateNewTaskView()
                    .environmentObject(taskViewModel)
                    .environmentObject(projectViewModel)
                    .environmentObject(userProfile)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
}
