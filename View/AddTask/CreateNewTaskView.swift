import SwiftUI

struct CreateNewTaskView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String = ""
    @State private var taskDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var remindMe: Bool = false
    @State private var comment: String = ""

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Верхний градиентный блок
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("New Task")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        TextField("Task Name", text: $taskName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.trailing)
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                }
                .ignoresSafeArea(edges: .top)

                // Нижний блок
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            DatePicker("", selection: $taskDate, displayedComponents: .date)
                                .labelsHidden()

                            Spacer()

                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }

                        Divider()

                        Text("Starting Time")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()

                            Text("-")

                            DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()

                            Spacer()

                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                        }

                        Divider()
                    }

                    HStack {
                        Image(systemName: "bell")
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text("Remind Me")
                        Spacer()
                        Toggle("", isOn: $remindMe)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comment")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "pencil")
                                .padding(.top, 4)
                                .foregroundColor(.gray)

                            TextEditor(text: $comment)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(18)
                                .foregroundColor(.white)
                        }
                    }

                    Button(action: {
                        let newTask = TaskModel(
                            id: UUID(),
                            title: taskName,
                            durationInMinutes: Int(endTime.timeIntervalSince(startTime) / 60),
                            date: taskDate,
                            isCompleted: false,
                            category: "", // категорий больше нет
                            remindMe: remindMe,
                            comment: comment
                        )
                        viewModel.addTask(newTask)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Task")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.top, 10)
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 40))
                .offset(y: -40)
            }
        }
    }
}

#Preview {
    CreateNewTaskView()
        .environmentObject(TaskViewModel())
}
