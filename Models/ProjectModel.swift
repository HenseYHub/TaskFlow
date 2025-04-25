//
//  ProjectModel.swift
//  TaskFlow
//
//  Created by Pavlo on 25.04.2025.
//

import Foundation

struct ProjectModel: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date
}



