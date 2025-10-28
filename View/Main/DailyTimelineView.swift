import SwiftUI

struct DailyTimelineView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @AppStorage("profileImageData") private var profileImageData: Data?

    @State private var showCreateProjectView = false
    @State private var selectedDate: Date = Date()
    @State private var selectedTaskID: UUID? = nil

    // whether there are any projects (to toggle empty state)
    private var hasProjects: Bool { !projectViewModel.projects.isEmpty }

    // tasks for the selected date
    var filteredTasks: [TaskModel] {
        let sameDayTasks = taskViewModel.tasks.filter {
            guard let taskDate = $0.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
        }
        return sameDayTasks.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedFullDate(selectedDate))
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("Today")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        } else {
                            Text(formattedWeekday(selectedDate))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    if let data = profileImageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 1))
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)

                // MARK: Calendar Scroll (2 weeks)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<14) { offset in
                                let date = Calendar.current.date(byAdding: .day, value: offset - 7, to: Date()) ?? Date()
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                                VStack(spacing: 6) {
                                    Text(dayNumber(date)).font(.headline)
                                    Text(shortWeekday(date)).font(.caption2)

                                    Circle()
                                        .fill(isSelected ? .black : .gray)
                                        .frame(width: 6, height: 6)
                                        .opacity(isSelected ? 1 : (hasTasks(on: date) ? 1 : 0))
                                }
                                .frame(width: 44, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(isSelected ? Color.white : Color.clear)
                                )
                                .foregroundColor(isSelected ? .black : .gray)
                                .id(offset)
                                .onTapGesture {
                                    withAnimation {
                                        selectedDate = date
                                        proxy.scrollTo(offset, anchor: .center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .onAppear {
                        let todayIndex = 7
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation { proxy.scrollTo(todayIndex, anchor: .center) }
                        }
                    }
                }
            }
            .padding(.top)

            // MARK: Tasks list (left date rail + card + swipes)
            List {
                Section {
                    ForEach(filteredTasks) { task in
                        HybridTaskRow(task: task) {
                            withAnimation {
                                taskViewModel.toggleTaskCompletion(task: task)
                            }
                        }
                        // swipe RIGHT → move to tomorrow
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    taskViewModel.moveTask(task, byDays: 1)
                                }
                            } label: {
                                Label("Tomorrow", systemImage: "arrow.right.circle")
                            }
                        }
                        // swipe LEFT → delete
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    taskViewModel.deleteTask(task)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    if filteredTasks.isEmpty {
                        Text("No tasks for this day")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .animation(.easeInOut, value: hasProjects)
        .fullScreenCover(isPresented: $showCreateProjectView) {
            CreateNewTaskView()
                .environmentObject(taskViewModel)
                .environmentObject(projectViewModel)
                .environmentObject(userProfile)
        }
    }

    // MARK: Helpers

    func hasTasks(on date: Date) -> Bool {
        taskViewModel.tasks.contains { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date) }
    }

    func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    func formattedWeekday(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#if DEBUG
#Preview {
    // mock profile for preview
    let profile = UserProfileModel()
    profile.profile = UserProfile(
        id: "preview",
        fullName: "Pasha",
        nickname: "pavlo.dev",
        profession: "iOS Dev",
        email: "p@example.com",
        avatarJPEGData: nil
    )

    return DailyTimelineView()
        .environmentObject(TaskViewModel())
        .environmentObject(profile)
        .environmentObject(ProjectViewModel())
}
#endif

// MARK: - Hybrid row (left date rail + task card)
private struct HybridTaskRow: View {
    let task: TaskModel
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left date rail
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayShort(task.date)).font(.caption2).foregroundColor(.gray)
                Text(dayNumber(task.date)).font(.title3.bold()).foregroundColor(.white)
            }
            .frame(width: 46, alignment: .leading)

            // Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .strikethrough(task.isCompleted)

                    Spacer()

                    if let s = task.startTime, let e = task.endTime {
                        Text("\(time(s))–\(time(e))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                if let c = task.comment, !c.isEmpty {
                    Text(c).font(.subheadline).foregroundColor(.gray).lineLimit(2)
                }

                Button(action: onToggle) {
                    Label(task.isCompleted ? "Marked as completed" : "Mark as completed",
                          systemImage: task.isCompleted ? "checkmark.square.fill" : "square")
                        .font(.footnote)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08)))
        }
        .contentShape(Rectangle())
    }

    // local helpers
    private func dayNumber(_ date: Date?) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date ?? Date())
    }
    private func weekdayShort(_ date: Date?) -> String {
        let f = DateFormatter(); f.dateFormat = "E"; return f.string(from: date ?? Date())
    }
    private func time(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// MARK: - ViewModel helpers for swipe actions
extension TaskViewModel {
    func deleteTask(_ task: TaskModel) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: idx)
        }
    }

    func moveTask(_ task: TaskModel, byDays days: Int = 1) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let cal = Calendar.current
        if let d = tasks[idx].date { tasks[idx].date = cal.date(byAdding: .day, value: days, to: d) }
        if let s = tasks[idx].startTime { tasks[idx].startTime = cal.date(byAdding: .day, value: days, to: s) }
        if let e = tasks[idx].endTime { tasks[idx].endTime = cal.date(byAdding: .day, value: days, to: e) }
    }
}
