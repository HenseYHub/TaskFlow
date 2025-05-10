import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var userProfile: UserProfileModel = UserProfileModel()
    
    @Published var tasks: [TaskModel] = []
    
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

}

