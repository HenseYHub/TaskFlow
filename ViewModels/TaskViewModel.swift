import Foundation
import SwiftUI

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var userProfile: UserProfileModel = UserProfileModel()

    // Любое изменение массива — сразу сохраняем на диск
    @Published var tasks: [TaskModel] = [] {
        didSet { saveToDisk() }
    }

    // MARK: - Init

    init() {
        loadFromDisk()
    }

    // MARK: - CRUD

    func addTask(_ task: TaskModel) {
        tasks.append(task)
    }

    func removeTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
    }

    func toggleTaskCompletion(task: TaskModel) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
        }
    }

    // Перегруженный addTask
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
    }

    // Обновление задачи целиком
    func updateTask(_ task: TaskModel) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    // MARK: - 🔥 Новый код — обновление времени задачи

    func updateTaskTime(task: TaskModel, newDate: Date?, newStart: Date?, newEnd: Date?) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        // Обновляем поля только если значения переданы
        if let d = newDate {
            tasks[index].date = d
        }
        if let s = newStart {
            tasks[index].startTime = s
        }
        if let e = newEnd {
            tasks[index].endTime = e
        }
    }

    // MARK: - Persistence

    private var storeURL: URL {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        // отдельная папка под ваше приложение
        let dir = appSupport.appendingPathComponent(Bundle.main.bundleIdentifier ?? "TaskFlow", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("tasks.json")
    }

    private func saveToDisk() {
        do {
            let enc = JSONEncoder()
            let data = try enc.encode(tasks)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("Save tasks error:", error)
            #endif
        }
    }

    private func loadFromDisk() {
        do {
            let data = try Data(contentsOf: storeURL)
            let dec = JSONDecoder()
            tasks = try dec.decode([TaskModel].self, from: data)
        } catch {
            tasks = [] // первый запуск или файла ещё нет
        }
    }
}
