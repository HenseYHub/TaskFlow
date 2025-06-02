import SwiftUI

struct AllTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel

    @State private var selectedTask: TaskModel? = nil
    @State private var showTaskInfo = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("All Tasks")
                .font(.largeTitle.bold())
                .padding()
                .foregroundColor(.white)

            if taskViewModel.tasks.isEmpty {
                Spacer()
                Text("У вас еще нет задач")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(taskViewModel.tasks) { task in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(task.name)
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Spacer()
                                }

                                if let comment = task.comment, !comment.isEmpty {
                                    Text(comment)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                Text("Дата: \(formattedDate(task.date ?? Date()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                if let start = task.startTime, let end = task.endTime {
                                    Text("Час: \(formattedTime(start)) – \(formattedTime(end))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    .padding()
                }
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .sheet(item: $selectedTask) { task in
            ProjectInfoSheetView(
                title: task.name,
                description: task.comment ?? "",
                date: task.date ?? Date(),
                startTime: task.startTime ?? Date(),
                endTime: task.endTime ?? Date()
            )
            .presentationDetents([.height(220)])
            .presentationBackground(.clear)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


#Preview {
    AllTaskView()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel())
}
