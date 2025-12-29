import Foundation

struct TaskModel: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var durationInMinutes: Int
    var date: Date?
    var isCompleted: Bool = false
    var note: String? = nil
    var category: String = "General"
    var remindMe: Bool = false
    var comment: String? = nil
    var project: String = "Default"
    var startTime: Date?
    var endTime: Date?

    /// Локализованный текст длительности, использует ключ `min_short`
    /// en: "min", de: "Min", uk: "хв"
    var durationText: String {
        let unit = NSLocalizedString("min_short",
                                     tableName: "Localizable",
                                     bundle: .main,
                                     comment: "Short unit for minutes")
        return "\(durationInMinutes) \(unit)"
    }
}
