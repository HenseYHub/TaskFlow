//
//  ProjectViewModel.swift
//  TaskFlow
//
//  Created by Pavlo on 25.04.2025.
//

import Foundation

class ProjectViewModel: ObservableObject {
    @Published var selectedProjectIndex: Int = 0

    @Published var projects: [ProjectModel] = [
        ProjectModel(
            title: "Game Design",
            description: "Create menu in dashboard & Make user flow",
            comment: "Main project screen",
            date: Date(),
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        )
    ]

    var selectedProject: ProjectModel? {
        guard selectedProjectIndex < projects.count else { return nil }
        return projects[selectedProjectIndex]
    }

    func updateProject(at index: Int, with updatedProject: ProjectModel) {
        guard projects.indices.contains(index) else { return }
        projects[index] = updatedProject
    }
}
