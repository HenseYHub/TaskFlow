import SwiftUI

struct CreateNewTaskView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @Environment(\.dismiss) private var dismiss

    // Поля
    @State private var taskName: String = ""
    @State private var taskDate: Date = Date()
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var comment: String = ""

    // Валидация/анимации
    @State private var showValidation = false
    @State private var shakeTrigger: CGFloat = 0
    @State private var flashTaskName = false

    // Быстрые пресеты длительности (минуты)
    private let durationPresets = [15, 30, 45, 60, 90, 120]
    @State private var selectedPreset: Int? = 60

    // Валидация
    var isFormValid: Bool { !taskName.isEmpty }

    // Текущая длительность
    private var currentDurationMinutes: Int {
        max(1, Int(endTime.timeIntervalSince(startTime) / 60))
    }

    var body: some View {
        ZStack {
            Color(red: 18/255, green: 18/255, blue: 20/255).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerView()
                    dateTimeView()
                    durationChips()
                    descriptionView()
                    createButton()
                }
                .padding(.top, 20)
            }
        }
        .onChange(of: startTime) { _ in adjustEndTimeFromPreset() }
        .onChange(of: taskDate) { _ in clampTaskDateToToday() }
        .onChange(of: endTime) { _ in syncPresetWithManualTime() }
    }

    // MARK: - Подвьюхи

    private func headerView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Create Task")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            TextField("Name", text: $taskName)
                .padding()
                .background(flashTaskName ? Color.gray.opacity(0.28) : (showValidation && taskName.isEmpty ? Color.gray.opacity(0.2) : Color.white.opacity(0.06)))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }

    private func dateTimeView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок + текущая длительность
            HStack {
                Text("Date & Time")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Duration: \(currentDurationMinutes)m")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Дата
            HStack {
                DatePicker("", selection: $taskDate, in: Date()..., displayedComponents: .date)
                    .labelsHidden()
                    .colorMultiply(.white)
                    .preferredColorScheme(.dark)
                Spacer()
                Image(systemName: "calendar").foregroundColor(.blue)
            }

            Divider().background(.gray.opacity(0.4))

            // Время
            Text("Time")
                .font(.caption)
                .foregroundColor(.gray)

            HStack(spacing: 16) {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorMultiply(.white)
                    .preferredColorScheme(.dark)

                Text("-").foregroundColor(.white)

                DatePicker("",
                           selection: $endTime,
                           in: startTime...(Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: taskDate) ?? Date()),
                           displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorMultiply(.white)
                    .preferredColorScheme(.dark)

                Spacer()
                Image(systemName: "clock").foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func durationChips() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick duration")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 68), spacing: 10)], spacing: 10) {
                ForEach(durationPresets, id: \.self) { mins in
                    Button {
                        selectedPreset = mins
                        setEndTime(minutes: mins)
                    } label: {
                        Text("\(mins)m")
                            .font(.callout.weight(.semibold))
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(selectedPreset == mins ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func descriptionView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.caption)
                .foregroundColor(.gray)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))

                TextEditor(text: $comment)
                    .padding(12)
                    .frame(minHeight: 110, alignment: .topLeading)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)

                if comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Add description…")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                }
            }
        }
        .padding(.horizontal)
    }

    private func createButton() -> some View {
        Button(action: createAction) {
            Text("Create")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.25))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .modifier(ShakeEffect(shakes: 1, animatableData: shakeTrigger))
        .padding(.horizontal)
    }

    // MARK: - Логика

    private func createAction() {
        guard isFormValid else {
            withAnimation(.default) {
                shakeTrigger += 1
                showValidation = true
            }
            if taskName.isEmpty {
                flashTaskName = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { flashTaskName = false }
            }
            return
        }

        let duration = currentDurationMinutes

        let newTask = TaskModel(
            id: UUID(),
            name: taskName,
            durationInMinutes: duration,
            date: taskDate,
            isCompleted: false,
            category: "",
            remindMe: false, // напоминания убрали в настройки
            comment: comment,
            project: projectViewModel.selectedProject?.title ?? "",
            startTime: startTime,
            endTime: endTime
        )

        viewModel.addTask(newTask)
        dismiss()
    }

    private func setEndTime(minutes: Int) {
        let cal = Calendar.current
        if let proposed = cal.date(byAdding: .minute, value: minutes, to: startTime) {
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 0, of: taskDate) ?? proposed
            endTime = min(proposed, endOfDay)
        }
    }

    private func adjustEndTimeFromPreset() {
        if let preset = selectedPreset {
            setEndTime(minutes: preset)
        } else {
            let cal = Calendar.current
            if endTime < startTime {
                endTime = cal.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
            }
            let endOfDay = cal.date(bySettingHour: 23, minute: 59, second: 0, of: taskDate) ?? endTime
            endTime = min(endTime, endOfDay)
        }
    }

    private func clampTaskDateToToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if taskDate < today { taskDate = today }
    }

    private func syncPresetWithManualTime() {
        // Если пользователь подвигал вручную endTime — подсветим пресет, если совпало.
        let diff = max(1, Int(endTime.timeIntervalSince(startTime) / 60))
        if durationPresets.contains(diff) {
            selectedPreset = diff
        } else {
            selectedPreset = nil
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
