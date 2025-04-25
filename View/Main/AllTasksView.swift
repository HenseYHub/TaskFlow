import SwiftUI

struct AllTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showTaskInfo: Bool = false
    @State private var selectedTask: TaskModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(taskViewModel.tasks.filter { $0.project == projectViewModel.selectedProject?.name }) { task in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(task.name)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Button(action: {
                                selectedTask = task
                                showTaskInfo = true
                            }) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                            }
                        }

                        if let comment = task.comment, !comment.isEmpty {
                            Text(comment)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Text("Дата: \(formattedDate(task.date ?? Date()))")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Час: \(formattedTime(task.date ?? Date(), duration: task.durationInMinutes))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
            }
            .padding()
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(item: $selectedTask) { task in
            ProjectInfoSheetView(
                title: task.name,
                description: task.comment ?? "",
                date: task.date ?? Date(),
                startTime: task.date ?? Date(),
                endTime: Calendar.current.date(byAdding: .minute, value: task.durationInMinutes, to: task.date ?? Date()) ?? Date()
            )
            .presentationDetents([.height(220)])
            .presentationBackground(.clear)
        }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date, duration: Int) -> String {
        let end = Calendar.current.date(byAdding: .minute, value: duration, to: date) ?? date
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: date)) – \(formatter.string(from: end))"
    }


#Preview {
    AllTaskView()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel())
}

