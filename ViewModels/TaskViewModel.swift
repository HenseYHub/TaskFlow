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
}
