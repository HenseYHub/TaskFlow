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
            project: "Game Design"
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
            project: "Game Design"
        )
    ]
    
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
}
