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

    /// Запуск фазы с возможностью стартовать с сохранённого остатка.
    func start(minutes: Int, from secondsLeftOverride: Int? = nil) {
        stop()
        didFinish = false
        totalSeconds = max(1, minutes) * 60
        if let override = secondsLeftOverride {
            secondsLeft = max(1, min(override, totalSeconds))
        } else {
            secondsLeft = totalSeconds
        }
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
    @Environment(\.locale) private var viewLocale
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var timer = FocusTimer()

    @State private var selectedTask: TaskModel?
    @State private var phase: FocusPhase = .focus
    @State private var showingTaskPicker = false

    // Остаток по фокус-фазе — теперь на КАЖДУЮ задачу отдельно
    @State private var remainingFocusByTask: [UUID: Int] = [:]
    @State private var totalFocusByTask:     [UUID: Int] = [:]

    // ✅ Остаток для фокуса БЕЗ выбранной задачи
    @State private var remainingFocusNoTask: Int = 0
    @State private var totalFocusNoTask:     Int = 0

    // Остатки для брейков — по фазе
    @State private var remainingByPhase: [FocusPhase: Int] = [.shortBreak: 0, .longBreak: 0]
    @State private var totalByPhase:     [FocusPhase: Int] = [:]

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

    private var primaryButtonTitleKey: LocalizedStringKey {
        if timer.isRunning { return "pause" }
        return isResumeState ? "resume" : "start"
    }
    private var primaryButtonIcon: String {
        timer.isRunning ? "pause.fill" : "play.fill"
    }

    // MARK: - Localization helpers

    /// Возвращает строку по ключу из таблицы "Localizable" именно для локали viewLocale.
    private func localized(_ key: String) -> String {
        let lang = viewLocale.language.languageCode?.identifier
            ?? viewLocale.identifier.split(separator: "_").first.map(String.init)
            ?? "en"

        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(key, tableName: "Localizable", bundle: bundle, comment: "")
        }
        return NSLocalizedString(key, tableName: "Localizable", bundle: .main, comment: "")
    }

    // Лейбл пресета — одна локализованная строка с плейсхолдером
    private var focusPresetLabel: Text {
        let format = localized("focus_preset_format") // "Focus • %d min" / "Fokus • %d Min" / "Фокус • %d хв"
        let text = String(format: format, locale: viewLocale, focusMinutes)
        return Text(text)
    }

    // MARK: - Phase state helpers

    private func defaultSeconds(for phase: FocusPhase) -> Int {
        switch phase {
        case .focus:      return focusMinutes * 60
        case .shortBreak: return 5 * 60
        case .longBreak:  return 15 * 60
        }
    }

    /// Сохраняем текущий прогресс активной фазы (учитывая выбранную задачу для focus)
    private func saveCurrentProgress() {
        switch phase {
        case .focus:
            if let id = selectedTask?.id {
                remainingFocusByTask[id] = max(0, timer.secondsLeft)
                totalFocusByTask[id]     = timer.totalSeconds
            } else {
                // ✅ когда нет выбранной задачи — сохраняем сюда
                remainingFocusNoTask = max(0, timer.secondsLeft)
                totalFocusNoTask     = timer.totalSeconds
            }
        case .shortBreak, .longBreak:
            remainingByPhase[phase] = max(0, timer.secondsLeft)
            totalByPhase[phase]     = timer.totalSeconds
        }
    }

    /// Загружаем состояние для заданной фазы и ставим на паузу
    private func loadPhaseState(_ p: FocusPhase) {
        switch p {
        case .focus:
            let total = defaultSeconds(for: .focus)

            let (saved, _): (Int, Int) = {
                if let id = selectedTask?.id {
                    return (remainingFocusByTask[id] ?? 0, totalFocusByTask[id] ?? total)
                } else {
                    return (remainingFocusNoTask, totalFocusNoTask > 0 ? totalFocusNoTask : total)
                }
            }()

            let remain = (saved > 0 && saved <= total) ? saved : total

            timer.pause()
            timer.isRunning    = false
            timer.didFinish    = false
            timer.totalSeconds = total
            timer.secondsLeft  = remain

        case .shortBreak, .longBreak:
            let total = defaultSeconds(for: p)
            totalByPhase[p] = total
            let saved = remainingByPhase[p] ?? 0
            let remain = (saved > 0 && saved <= total) ? saved : total

            timer.pause()
            timer.isRunning    = false
            timer.didFinish    = false
            timer.totalSeconds = total
            timer.secondsLeft  = remain
        }
    }

    /// Переключение фазы: сохранить текущую, пауза, подставить сохранённое время новой фазы
    private func switchPhase(to newPhase: FocusPhase) {
        saveCurrentProgress()
        phase = newPhase
        loadPhaseState(newPhase)
        UIApplication.shared.isIdleTimerDisabled = false
        cancelScheduledCompletion()
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 20) {
            header
            taskPickerButton
            presetsRow
            timerCircle

            Spacer(minLength: 0)

            if selectedTask == nil && !todayTasks.isEmpty {
                Text("tip_select_task")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                    .padding(.top, 4)
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showingTaskPicker) {
            TaskPickerSheet(todayTasks: todayTasks, selected: $selectedTask)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // Не перезагружаем, если уже есть состояние
        .onAppear {
            if !timer.isRunning && timer.totalSeconds == 0 && timer.secondsLeft == 0 {
                loadPhaseState(phase)
            }
        }
        // Сохраняем при уходе в фон
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                saveCurrentProgress()
            }
        }
        // Смена задачи: сохраняем старую (включая "без задачи"), ставим паузу, грузим состояние новой
        .onChange(of: selectedTask, initial: false) { oldTask, _ in
            if phase == .focus {
                if let oldId = oldTask?.id {
                    remainingFocusByTask[oldId] = max(0, timer.secondsLeft)
                    totalFocusByTask[oldId]     = timer.totalSeconds
                } else {
                    // ✅ раньше задачи не было
                    remainingFocusNoTask = max(0, timer.secondsLeft)
                    totalFocusNoTask     = timer.totalSeconds
                }
            }

            timer.pause()
            UIApplication.shared.isIdleTimerDisabled = false
            cancelScheduledCompletion()

            if phase == .focus {
                loadPhaseState(.focus)
            }
        }
        .onChange(of: timer.didFinish, initial: false) { _, finished in
            guard finished else { return }
            UIApplication.shared.isIdleTimerDisabled = false

            switch phase {
            case .focus:
                if let id = selectedTask?.id {
                    remainingFocusByTask[id] = 0
                    totalFocusByTask[id]     = timer.totalSeconds
                } else {
                    // ✅ завершили фокус без задачи
                    remainingFocusNoTask = 0
                    totalFocusNoTask     = timer.totalSeconds
                }
                if let t = selectedTask {
                    taskVM.toggleTaskCompletion(task: t)
                }
                // Автопереключение на короткий перерыв (на паузе)
                switchPhase(to: .shortBreak)

            case .shortBreak, .longBreak:
                remainingByPhase[phase] = 0
            }

            cancelScheduledCompletion()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("focus_title")
                    .font(.title.bold())
                    .foregroundColor(.white)
                Text(Date(), style: .date)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var taskPickerButton: some View {
        Button { showingTaskPicker = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("current_task")
                        .font(.caption)
                        .foregroundColor(.gray)

                    if let name = selectedTask?.name {
                        Text(name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    } else {
                        Text("select_a_task")
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                    }
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                presetButton(isActive: phase == .focus) {
                    switchPhase(to: .focus)
                } label: { focusPresetLabel }

                presetButton(isActive: phase == .shortBreak) {
                    switchPhase(to: .shortBreak)
                } label: { Text("break_5") }

                presetButton(isActive: phase == .longBreak) {
                    switchPhase(to: .longBreak)
                } label: { Text("break_15") }
            }
            .padding(.horizontal)
        }
    }

    private func presetButton(
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button(action: action) {
            label()
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .allowsTightening(true)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(isActive ? Color.blue.opacity(0.25) : Color.white.opacity(0.06))
                .foregroundColor(isActive ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .layoutPriority(1)
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
                // Start / Pause / Resume
                Button {
                    if timer.isRunning {
                        // Пауза
                        saveCurrentProgress()
                        timer.pause()
                        UIApplication.shared.isIdleTimerDisabled = false
                        cancelScheduledCompletion()
                    } else if isResumeState {
                        // Резюмируем с сохранённого остатка
                        let total = defaultSeconds(for: phase)
                        let startFrom: Int
                        switch phase {
                        case .focus:
                            if let id = selectedTask?.id {
                                let saved = remainingFocusByTask[id] ?? timer.secondsLeft
                                startFrom = (saved > 0 && saved <= total) ? saved : max(1, timer.secondsLeft)
                            } else {
                                let saved = (remainingFocusNoTask > 0) ? remainingFocusNoTask : timer.secondsLeft
                                startFrom = (saved > 0 && saved <= total) ? saved : max(1, timer.secondsLeft)
                            }
                        case .shortBreak, .longBreak:
                            let saved = remainingByPhase[phase] ?? timer.secondsLeft
                            startFrom = (saved > 0 && saved <= total) ? saved : max(1, timer.secondsLeft)
                        }
                        timer.start(minutes: total / 60, from: startFrom)
                        UIApplication.shared.isIdleTimerDisabled = true
                        scheduleCompletionNotification(in: startFrom)
                    } else {
                        // Первый старт фазы
                        startSession()
                    }
                } label: {
                    HStack {
                        Image(systemName: primaryButtonIcon)
                        Text(primaryButtonTitleKey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Reset — только текущая фаза
                Button {
                    switch phase {
                    case .focus:
                        if let id = selectedTask?.id {
                            remainingFocusByTask[id] = 0
                        } else {
                            remainingFocusNoTask = 0
                        }
                    case .shortBreak, .longBreak:
                        remainingByPhase[phase] = 0
                    }
                    loadPhaseState(phase) // вернёт на полный объём и паузу
                    UIApplication.shared.isIdleTimerDisabled = false
                    cancelScheduledCompletion()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("reset")
                    }
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
        let total = defaultSeconds(for: phase)
        let startFrom: Int
        switch phase {
        case .focus:
            if let id = selectedTask?.id {
                let saved = remainingFocusByTask[id] ?? 0
                startFrom = (saved > 0 && saved <= total) ? saved : total
            } else {
                let saved = remainingFocusNoTask
                startFrom = (saved > 0 && saved <= total) ? saved : total
            }
        case .shortBreak, .longBreak:
            let saved = remainingByPhase[phase] ?? 0
            startFrom = (saved > 0 && saved <= total) ? saved : total
        }

        timer.start(minutes: total / 60, from: startFrom)
        UIApplication.shared.isIdleTimerDisabled = true
        requestNotificationsIfNeeded()
        scheduleCompletionNotification(in: startFrom)
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
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                (Text("\(task.durationInMinutes) ") + Text("min_short"))
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)                    // убираем системный белый фон
            .background(AppColorPalette.background)              // фон списка

            .navigationTitle(Text("select_task_title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("clear") { selected = nil }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
            .toolbarBackground(AppColorPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .background(AppColorPalette.background)                  // запасной фон
    }

    private func fmt(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: d)
    }
}


// MARK: - Уведомления
private func requestNotificationsIfNeeded() {
    UNUserNotificationCenter.current().getNotificationSettings { s in
        if s.authorizationStatus == .notDetermined {
            UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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
