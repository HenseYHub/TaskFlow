import SwiftUI

enum AllTasksFilter: Int, CaseIterable {
    case all
    case completed
}

struct AllTasksView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var projectVM: ProjectViewModel

    @State private var filter: AllTasksFilter = .all
    @State private var query: String = ""

    private var allCount: Int { taskVM.tasks.count }
    private var completedCount: Int { taskVM.tasks.filter { $0.isCompleted }.count }

    private var tasksForFilter: [TaskModel] {
        switch filter {
        case .all:
            return taskVM.tasks
        case .completed:
            return taskVM.tasks.filter { $0.isCompleted }
        }
    }

    private var filteredTasks: [TaskModel] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let searched = tasksForFilter.filter { t in
            if q.isEmpty { return true }

            let name = t.name.lowercased()
            let comment = (t.comment ?? "").lowercased()

            return name.contains(q) || comment.contains(q)
        }

        return searched.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }

            let d0 = $0.date ?? .distantPast
            let d1 = $1.date ?? .distantPast
            if d0 != d1 { return d0 > d1 }

            return ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast)
        }
    }

    var body: some View {
        ZStack {
            AppColorPalette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {

                    searchField

                    Picker("", selection: $filter) {
                        Text("\(String(localized: "all")) (\(allCount))").tag(AllTasksFilter.all)
                        Text("\(String(localized: "completed")) (\(completedCount))").tag(AllTasksFilter.completed)
                    }
                    .pickerStyle(.segmented)

                    if filteredTasks.isEmpty {
                        emptyState
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredTasks) { task in
                                TaskCardRow(task: task) {
                                    toggleCompleted(task)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("all_tasks")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func toggleCompleted(_ task: TaskModel) {
        guard let index = taskVM.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        taskVM.tasks[index].isCompleted.toggle()

    }

    // MARK: - UI

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(String(localized: "search_tasks"), text: $query)
                .foregroundColor(.white)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(true)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 34))
                .foregroundColor(.gray)

            Text(filter == .completed ? "no_completed_tasks" : "no_tasks_yet")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Card Row
struct TaskCardRow: View {
    let task: TaskModel
    var onToggleCompleted: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {

            Button {
                onToggleCompleted?()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {

                Text(task.name)
                    .foregroundColor(.white)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(dateText(task.date))
                    Text("•")
                    Text("\(fmtTime(task.startTime))–\(fmtTime(task.endTime))")
                }
                .foregroundColor(.gray)
                .font(.caption)

                if let c = task.comment, !c.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(c)
                        .foregroundColor(.white.opacity(0.75))
                        .font(.caption)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer()

            
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func fmtTime(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

#Preview {
    NavigationStack {
        AllTasksView()
            .environmentObject(TaskViewModel())
            .environmentObject(ProjectViewModel())
    }
}
