
import Foundation

class ProjectViewModel: ObservableObject {
    @Published var selectedProjectIndex: Int = 0

    @Published var projects: [ProjectModel] = []


    var selectedProject: ProjectModel? {
        guard selectedProjectIndex < projects.count else { return nil }
        return projects[selectedProjectIndex]
    }

    func updateProject(at index: Int, with updatedProject: ProjectModel) {
        guard projects.indices.contains(index) else { return }
        projects[index] = updatedProject
    }
    
    func addProject(_ project: ProjectModel) {
        projects.append(project)
    }

}

