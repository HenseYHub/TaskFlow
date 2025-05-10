import SwiftUI

struct CreateNewTaskView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var taskName: String = ""
    @State private var taskDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var remindMe: Bool = false
    @State private var comment: String = ""
    @State private var selectedType: String? = nil

    @State private var showValidation = false
    @State private var showAlert = false
    @State private var shakeTrigger: CGFloat = 0
    @State private var flashTaskName = false
    @State private var flashTypeSelection = false

    var isFormValid: Bool {
        !taskName.isEmpty && selectedType != nil
    }

    var body: some View {
        ZStack {
            Color(red: 18/255, green: 18/255, blue: 20/255).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Заголовок + крестик
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Create New")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)

                            Spacer()

                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        // Название
                        TextField("Name", text: $taskName)
                            .padding()
                            .background(flashTaskName ? Color.gray.opacity(0.3) :
                                        (showValidation && taskName.isEmpty ? Color.gray.opacity(0.2) : Color.white.opacity(0.05)))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // Кнопки выбора типа
                    HStack(spacing: 16) {
                        ForEach(["Task", "Project"], id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                Text(type)
                                    .fontWeight(.semibold)
                                    .frame(width: 140, height: 60)
                                    .foregroundColor(selectedType == type ? .white : .gray)
                                    .background(
                                        flashTypeSelection && selectedType == nil
                                            ? Color.gray.opacity(0.3)
                                            : (selectedType == type
                                                ? Color.blue.opacity(0.2)
                                                : Color.white.opacity(0.05))
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Дата и время
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            DatePicker("", selection: $taskDate, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                                .colorMultiply(.white)
                                .preferredColorScheme(.dark)

                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                        }

                        Divider().background(.gray)

                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 16) {
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorMultiply(.white)
                                .preferredColorScheme(.dark)

                            Text("-")
                                .foregroundColor(.white)

                            DatePicker("", selection: $endTime, in: startTime...(Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: taskDate) ?? Date()), displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .colorMultiply(.white)
                                .preferredColorScheme(.dark)

                            Spacer()
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                        }

                        Divider().background(.gray)

                        HStack {
                            Image(systemName: "bell")
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text("Remind Me")
                                .foregroundColor(.white)

                            Spacer()

                            Toggle("", isOn: $remindMe)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

                    // Описание
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextEditor(text: $comment)
                            .frame(height: 100)
                            .padding(12)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // Кнопка создания
                    Button(action: {
                        if isFormValid {
                            if selectedType == "Project" {
                                let newProject = ProjectModel(
                                    title: taskName,
                                    description: comment,
                                    comment: comment,
                                    date: taskDate,
                                    startTime: startTime,
                                    endTime: endTime
                                )
                                projectViewModel.addProject(newProject)
                            } else {
                                let newTask = TaskModel(
                                    id: UUID(),
                                    name: taskName,
                                    durationInMinutes: Int(endTime.timeIntervalSince(startTime) / 60),
                                    date: taskDate,
                                    isCompleted: false,
                                    category: "",
                                    remindMe: remindMe,
                                    comment: comment,
                                    project: selectedType ?? "",
                                    startTime: startTime,
                                    endTime: endTime
                                )
                                viewModel.addTask(newTask)
                            }
                            dismiss()
                        } else {
                            withAnimation(.default) {
                                shakeTrigger += 1
                                showValidation = true
                                showAlert = true
                            }

                            // Flash поля
                            if taskName.isEmpty {
                                flashTaskName = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    flashTaskName = false
                                }
                            }

                            if selectedType == nil {
                                flashTypeSelection = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    flashTypeSelection = false
                                }
                            }
                        }
                    }) {
                        Text("Create")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .modifier(ShakeEffect(shakes: 1, animatableData: shakeTrigger))
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            }
        }
        .onChange(of: startTime) {
            let calendar = Calendar.current
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: taskDate) ?? Date()
            let suggestedEndTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? startTime
            endTime = min(suggestedEndTime, endOfDay)
        }
        .onChange(of: taskDate) {
            let today = Calendar.current.startOfDay(for: Date())
            if taskDate < today {
                taskDate = today
            }
        }
    }
}

// Анимация тряски
struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat = 0
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = 10 * sin(animatableData * .pi * 2)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#Preview {
    CreateNewTaskView()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel())
}
