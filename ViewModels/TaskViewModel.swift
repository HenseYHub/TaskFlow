import Foundation
import SwiftUI

@MainActor
final class TaskViewModel: ObservableObject {

    // ✅ настройка "за сколько минут напоминать"
    @AppStorage("remindLeadMinutes") private var remindLeadMinutes: Int = 10

    // Текущий пользователь
    @Published private(set) var currentUserId: String? = nil

    // Любое изменение массива — сохраняем на диск (но только если userId есть)
    @Published var tasks: [TaskModel] = [] {
        didSet { saveToDiskIfPossible() }
    }

    // ✅ Fallback id, чтобы уведомления работали даже без логина
    private var effectiveUserId: String { currentUserId ?? "local" }

    // MARK: - Init
    init() {}

    // MARK: - Bind user (ВАЖНО)

    /// Вызывать при логине/логауте/смене аккаунта
    func bindToUser(_ userId: String?) {
        // 1) очистить UI сразу, чтобы не мигали старые данные
        tasks = []

        // 2) обновить current user
        currentUserId = userId

        // 3) если пользователь вышел
        guard userId != nil else { return }

        // 4) загрузить данные нового пользователя
        loadFromDisk()
    }

    // MARK: - CRUD

    func addTask(_ task: TaskModel) {
        tasks.append(task)
        scheduleNotificationsIfNeeded(for: task)
    }

    func removeTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
        cancelNotifications(for: task.id)
    }

    func toggleTaskCompletion(task: TaskModel) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].isCompleted.toggle()

        if tasks[index].isCompleted {
            cancelNotifications(for: task.id)
        } else {
            scheduleNotificationsIfNeeded(for: tasks[index])
        }
    }

    func addTask(
        name: String,
        durationInMinutes: Int,
        date: Date?,
        isCompleted: Bool = false,
        note: String? = nil,
        category: String = "General",
        remindMe: Bool,
        comment: String?,
        project: String,
        startTime: Date?,
        endTime: Date?
    ) {
        let newTask = TaskModel(
            id: UUID(),
            name: name,
            durationInMinutes: durationInMinutes,
            date: date,
            isCompleted: isCompleted,
            note: note,
            category: category,
            remindMe: remindMe,
            comment: comment,
            project: project,
            startTime: startTime,
            endTime: endTime
        )

        tasks.append(newTask)
        scheduleNotificationsIfNeeded(for: newTask)
    }

    func updateTask(_ task: TaskModel) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        cancelNotifications(for: task.id)
        tasks[idx] = task
        scheduleNotificationsIfNeeded(for: task)
    }

    func updateTaskTime(task: TaskModel, newDate: Date?, newStart: Date?, newEnd: Date?) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        cancelNotifications(for: task.id)

        if let d = newDate { tasks[index].date = d }
        if let s = newStart { tasks[index].startTime = s }
        if let e = newEnd { tasks[index].endTime = e }

        scheduleNotificationsIfNeeded(for: tasks[index])
    }

    /// Пересоздать уведомления для всех задач (например при старте)
    func rescheduleAllNotifications() {
        let uid = effectiveUserId

        Task {
            for t in tasks {
                NotificationScheduler.shared.cancelAll(for: t.id, userId: uid)

                guard t.remindMe else { continue }
                guard let startDate = startDateForNotifications(from: t) else { continue }

                await NotificationScheduler.shared.scheduleOne(
                    userId: uid,
                    taskId: t.id,
                    taskTitle: t.name,
                    startDate: startDate,
                    leadMinutes: remindLeadMinutes
                )
            }
        }
    }

    // MARK: - Notifications helpers

    private func scheduleNotificationsIfNeeded(for task: TaskModel) {
        Task {
            let uid = effectiveUserId

            guard task.remindMe else { return }
            guard !task.isCompleted else { return }
            guard let startDate = startDateForNotifications(from: task) else { return }

            await NotificationScheduler.shared.scheduleOne(
                userId: uid,
                taskId: task.id,
                taskTitle: task.name,
                startDate: startDate,
                leadMinutes: remindLeadMinutes
            )
        }
    }

    private func cancelNotifications(for taskId: UUID) {
        let uid = effectiveUserId
        NotificationScheduler.shared.cancelAll(for: taskId, userId: uid)
    }

    private func startDateForNotifications(from task: TaskModel) -> Date? {
        if let start = task.startTime {
            if let d = task.date {
                return combine(date: d, time: start)
            }
            return start
        }
        return task.date
    }

    private func combine(date: Date, time: Date) -> Date? {
        let cal = Calendar.current
        let d = cal.dateComponents([.year, .month, .day], from: date)
        let t = cal.dateComponents([.hour, .minute], from: time)

        var comps = DateComponents()
        comps.year = d.year
        comps.month = d.month
        comps.day = d.day
        comps.hour = t.hour
        comps.minute = t.minute

        return cal.date(from: comps)
    }

    // MARK: - Persistence

    private func userSafeId(_ id: String) -> String {
        id.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private var storeURL: URL? {
        guard let uid = currentUserId else { return nil }

        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        let baseDir = appSupport.appendingPathComponent(
            Bundle.main.bundleIdentifier ?? "TaskFlow",
            isDirectory: true
        )

        if !fm.fileExists(atPath: baseDir.path) {
            try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
        }

        let filename = "tasks_\(userSafeId(uid)).json"
        return baseDir.appendingPathComponent(filename)
    }

    private func saveToDiskIfPossible() {
        guard let url = storeURL else { return }
        do {
            let enc = JSONEncoder()
            let data = try enc.encode(tasks)
            try data.write(to: url, options: [.atomic])
        } catch {
            #if DEBUG
            print("Save tasks error:", error)
            #endif
        }
    }

    private func loadFromDisk() {
        guard let url = storeURL else {
            tasks = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            tasks = try dec.decode([TaskModel].self, from: data)
        } catch {
            tasks = []
        }
    }
}
