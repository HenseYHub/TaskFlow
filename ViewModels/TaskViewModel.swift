//
//  TaskViewModel.swift
//  TaskFlow
//
//  Created by Pavlo on 22.04.2025.
//

import Foundation
import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var userProfile: UserProfileModel = UserProfileModel()
    @Published var tasks: [TaskModel] = [
        TaskModel(
            id: UUID(),
            title: "Учёба (Swift)",
            durationInMinutes: 120,
            date: Date(),
            isCompleted: false,
            category: "Study",      // ← добавлено
            remindMe: true          // ← добавлено
            
        ),
        TaskModel(
            id: UUID(),
            title: "Прогулка",
            durationInMinutes: 45,
            date: Date(),
            isCompleted: true,
            category: "Life",       // ← добавлено
            remindMe: false         // ← добавлено
        )
    ]

    
    func addTask(_ task: TaskModel) {
        tasks.append(task)
    }

    func removeTask(_ task: TaskModel) {
        tasks.removeAll { $0.id == task.id }
    }
}
