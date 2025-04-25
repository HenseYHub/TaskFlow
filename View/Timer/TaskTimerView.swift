import SwiftUI

struct TaskTimerView: View {
    @ObservedObject var timerVM: TimerViewModel
    var task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showTimePicker = false
    @State private var tempDuration: Int = 25

    let predefinedDurations: [Int] = [15, 30, 45, 60, 90, 120, 150, 180, 210, 240]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(timerVM.formattedTime)
                    .font(.system(size: 60, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()

                VStack(spacing: 12) {
                    if timerVM.remainingSeconds > 0 {
                        if !timerVM.hasStarted {
                            Button("Старт") {
                                timerVM.start()
                                NotificationManager.instance.scheduleNotification(
                                    title: "Задача завершена!",
                                    subtitle: "\"\(task.title)\" завершена 🎉",
                                    date: Date().addingTimeInterval(Double(timerVM.remainingSeconds))
                                )
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Изменить время") {
                                tempDuration = timerVM.remainingSeconds / 60
                                showTimePicker.toggle()
                            }
                            .buttonStyle(.bordered)
                        } else if timerVM.isRunning {
                            Button("Пауза") {
                                timerVM.pause()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Старт") {
                                timerVM.start()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    Button("Завершить") {
                        timerVM.stop()
                        if let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) {
                            viewModel.tasks[index].isCompleted = true
                        }
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(.horizontal)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Таймер")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            timerVM.stop()
        }
        .sheet(isPresented: $showTimePicker) {
            VStack(spacing: 16) {
                Text("Изменить продолжительность")
                    .font(.headline)
                    .foregroundColor(.white)

                Picker("Минуты", selection: $tempDuration) {
                    ForEach(predefinedDurations, id: \.self) { minute in
                        Text(formattedDuration(minute)).tag(minute)
                            .foregroundColor(.white)
                    }
                }
                .labelsHidden()
                .pickerStyle(.wheel)

                Button("Применить") {
                    timerVM.remainingSeconds = tempDuration * 60
                    timerVM.totalSeconds = tempDuration * 60
                    showTimePicker = false
                }
                .padding()
            }
            .padding()
            .background(AppColors.background)
        }
    }

    func formattedDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) мин"
        } else {
            let hours = minutes / 60
            let remaining = minutes % 60
            return remaining == 0 ? "\(hours) ч" : "\(hours) ч \(remaining) мин"
        }
    }
}

// Превью
#Preview {
    TaskTimerView(
        timerVM: TimerViewModel(durationInMinutes: 25),
        task: TaskModel.sample,
        viewModel: TaskViewModel()
    )
}
