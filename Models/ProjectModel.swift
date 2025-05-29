import Foundation

struct ProjectModel: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var comment: String
    var date: Date
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool = false

    // Инициализатор с поддержкой кастомного id
    init(id: UUID = UUID(), title: String, description: String, comment: String, date: Date, startTime: Date, endTime: Date) {
        self.id = id
        self.title = title
        self.description = description
        self.comment = comment
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
    }
}



