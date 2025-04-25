//
//  TaskModel.swift
//  TaskFlow
//
//  Created by Pavlo on 22.04.2025.
//

import Foundation

struct TaskModel: Identifiable, Hashable {
    let id: UUID
    var title: String
    var durationInMinutes: Int
    var date: Date?
    var isCompleted: Bool
    var note: String? = nil
    var category: String
    var remindMe: Bool
    var comment: String?
    var durationText: String {
        return "\(durationInMinutes) мин"
    }

    static let sample = TaskModel(
        id: UUID(),
        title: "Учёба (Swift)",
        durationInMinutes: 25,
        date: Date(),
        isCompleted: false,
        category: "Study",        
        remindMe: false
    )

}
