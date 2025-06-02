import Foundation

struct TaskModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var durationInMinutes: Int
    var date: Date?
    var isCompleted: Bool
    var note: String? = nil
    var category: String
    var remindMe: Bool
    var comment: String?
    var project: String
    var startTime: Date?
    var endTime: Date?


    var durationText: String {
        return "\(durationInMinutes) хв"
    }
}
