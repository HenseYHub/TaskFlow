import SwiftUI
import UserNotifications

// MARK: - Таймер без Timer (устойчивый)

@MainActor
final class FocusTimer: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var secondsLeft: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var didFinish: Bool = false

    private var tickerTask: Task<Void, Never>?

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - secondsLeft) / Double(totalSeconds)
    }

    func start(minutes: Int) {
        stop()
        didFinish = false
        totalSeconds = max(1, minutes) * 60
        secondsLeft  = totalSeconds
        isRunning = true
        runTimer()
    }

    func pause() {
        isRunning = false
        stop()
    }

    func resume() {
        guard secondsLeft > 0 else { return }
        isRunning = true
        runTimer()
    }

    func reset() {
        stop()
        isRunning = false
        didFinish = false
        secondsLeft = 0
        totalSeconds = 0
    }

    private func runTimer() {
        stop()
        tickerTask = Task { [weak self] in
            guard let self else { return }
            while true {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                if self.secondsLeft <= 0 { break }
                self.secondsLeft -= 1
            }
            if !Task.isCancelled && self.secondsLeft <= 0 {
                self.isRunning = false
                self.didFinish = true
            }
        }
    }

    private func stop() {
        tickerTask?.cancel()
        tickerTask = nil
    }
}

// MARK: - Фазы

enum FocusPhase: String, CaseIterable {
    case focus
    case shortBreak
    case longBreak
}

// MARK: - Focus View

struct FocusView: View {
    @EnvironmentObject var taskVM: TaskViewModel

    @StateObject private var timer = FocusTimer()

    @State private var selectedTask: TaskModel?
    @State private var phase: FocusPhase = .focus
    @State private var showingTaskPicker = false

    // MARK: - Derived

    private var focusMinutes: Int {
        selectedTask?.durationInMinutes ?? 25
    }

    private var currentMinutes: Int {
        switch phase {
        case .focus:      return focusMinutes
        case .shortBreak: return 5
        case .longBreak:  return 15
        }
    }

    private var todayTasks: [TaskModel] {
        let cal = Calendar.current
        return taskVM.tasks
            .filter { $0.date.map { cal.isDateInToday($0) } ?? false }
            .filter { !$0.isCompleted }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var isResumeState: Bool {
        !timer.isRunning && timer.secondsLeft > 0 && timer.secondsLeft != currentMinutes * 60
    }

    private var primaryButtonTitle: String {
        if timer.isRunning { return String(localized: "pause") }
        return isResumeState ? String(localized: "resume") : String(localized: "start")
    }
    private var primaryButtonIcon: String {
        timer.isRunning ? "pause.fill" : "play.fill"
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            header
            taskPickerButton
            presetsRow
            timerCircle

            Spacer()

            if selectedTask == nil && !todayTasks.isEmpty {
                Text("tip_select_task")
                    .font(.footnote).foregroundColor(.gray).padding(.bottom, 8)
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerSheet(todayTasks: todayTasks, selected: $selectedTask)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: selectedTask, initial: false) { _, _ in
            if phase == .focus && !timer.isRunning {
                timer.reset()
            }
        }
        .onChange(of: timer.didFinish, initial: false) { _, finished in
            guard finished else { return }
            UIApplication.shared.isIdleTimerDisabled = false
            if phase == .focus, let t = selectedTask {
                taskVM.toggleTaskCompletion(task: t)
            }
            if phase == .focus { phase = .shortBreak }
            cancelScheduledCompletion()
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("focus_title").font(.title.bold()).foregroundColor(.white)
                Text(Date(), style: .date).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var taskPickerButton: some View {
        Button { showingTaskPicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("current_task").font(.caption).foregroundColor(.gray)
                    Text(selectedTask?.name ?? String(localized: "select_a_task"))
                        .font(.headline).foregroundColor(.white).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }

    private var presetsRow: some View {
        HStack(spacing: 10) {
            // "Focus • {minutes}m"
            presetButton(
                title: "\(String(localized: "focus_title")) • \(focusMinutes)\(String(localized: "minutes_short"))",
                isActive: phase == .focus
            ) {
                phase = .focus; if !timer.isRunning { timer.reset() }
            }

            presetButton(title: String(localized: "break_5"), isActive: phase == .shortBreak) {
                phase = .shortBreak; if !timer.isRunning { timer.reset() }
            }
            presetButton(title: String(localized: "break_15"), isActive: phase == .longBreak) {
                phase = .longBreak; if !timer.isRunning { timer.reset() }
            }
        }
        .padding(.horizontal)
    }

    private func presetButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.blue.opacity(0.25) : Color.white.opacity(0.06))
                .foregroundColor(isActive ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var timerCircle: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 14)

                Circle()
                    .trim(from: 0, to: CGFloat(timer.progress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: timer.progress)

                Text(timeString(timer.secondsLeft))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .frame(width: 260, height: 260)

            HStack(spacing: 12) {
                Button {
                    if timer.isRunning {
                        timer.pause()
                        UIApplication.shared.isIdleTimerDisabled = false
                    } else if isResumeState {
                        timer.resume()
                        UIApplication.shared.isIdleTimerDisabled = true
                    } else {
                        startSession()
                    }
                } label: {
                    Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    timer.reset()
                    UIApplication.shared.isIdleTimerDisabled = false
                    cancelScheduledCompletion()
                } label: {
                    Label(String(localized: "reset"), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func startSession() {
        timer.start(minutes: currentMinutes)
        UIApplication.shared.isIdleTimerDisabled = true
        requestNotificationsIfNeeded()
        scheduleCompletionNotification(in: currentMinutes * 60)
    }

    private func timeString(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        let m = clamped / 60, s = clamped % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Пикер задач

private struct TaskPickerSheet: View {
    let todayTasks: [TaskModel]
    @Binding var selected: TaskModel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if todayTasks.isEmpty {
                    Text("no_tasks_today")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(todayTasks) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.name).font(.body)
                                if let s = task.startTime, let e = task.endTime {
                                    Text("\(fmt(s))–\(fmt(e))")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                Text("\(task.durationInMinutes) \(String(localized: "min_short"))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selected?.id == task.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selected = task }
                    }
                }
            }
            .navigationTitle(String(localized: "select_task_title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(String(localized: "clear")) { selected = nil } }
                ToolbarItem(placement: .topBarTrailing) { Button(String(localized: "done")) { dismiss() } }
            }
        }
    }

    private func fmt(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}

// MARK: - Уведомления

private func requestNotificationsIfNeeded() {
    UNUserNotificationCenter.current().getNotificationSettings { s in
        if s.authorizationStatus == .notDetermined {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}

private func scheduleCompletionNotification(in seconds: Int) {
    let c = UNMutableNotificationContent()
    c.title = String(localized: "notif_times_up")
    c.body  = String(localized: "notif_focus_complete")
    c.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
    let req = UNNotificationRequest(identifier: "focus-complete", content: c, trigger: trigger)
    UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
}

private func cancelScheduledCompletion() {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-complete"])
}

// MARK: - Preview

#Preview {
    FocusView()
        .environmentObject(TaskViewModel())
}
