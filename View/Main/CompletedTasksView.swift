import SwiftUI

struct CompletedTasksView: View {
    @ObservedObject var viewModel: TaskViewModel

    var completedTasks: [TaskModel] {
        viewModel.tasks.filter { $0.isCompleted }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea() // Тёмный фон

            VStack(alignment: .leading, spacing: 16) {
                Text("Завершённые задачи")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)

                if completedTasks.isEmpty {
                    Text("Немає завершених задач 🙌")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 50)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(completedTasks) { task in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("\(task.durationInMinutes) хв")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            let tasksToRemove = indexSet.map { completedTasks[$0] }
                            for task in tasksToRemove {
                                viewModel.removeTask(task)
                            }
                        }
                    }

                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CompletedTasksView(viewModel: TaskViewModel())
}
