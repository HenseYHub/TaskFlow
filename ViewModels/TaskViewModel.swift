import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var userProfile: UserProfileModel = UserProfileModel()
    
    @Published var tasks: [TaskModel] = [
        TaskModel(
            id: UUID(),
            name: "Учёба (Swift)",
            durationInMinutes: 120,
            date: Date(),
            isCompleted: false,
            category: "Study",
            remindMe: true,
            comment: "Прохожу SwiftUI",
            project: "Game Design" // ✅ добавили проект
        ),
        TaskModel(
            id: UUID(),
            name: "Прогулка",
            durationInMinutes: 45,
            date: Date(),
            isCompleted: true,
            category: "Life",
            remindMe: false,
            comment: "Гулял по парку",
            project: "Game Design" // ✅ добавили проект
        )
    ]
    
    func addTask(_ task: TaskModel) {
        tasks.append(task)
    }
    
    func removeTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
    }
}
