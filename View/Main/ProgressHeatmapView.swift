import SwiftUI
import Charts

struct ProgressHeatmapView: View {
    @EnvironmentObject var taskVM: TaskViewModel

    private let columns = 53
    private let rows = 7
    private let cellSize: CGFloat = 14
    private let spacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Progress")
                .font(.title.bold())
                .foregroundColor(.white)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    // Day labels: Mon, Wed, Fri
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            if row % 2 == 0 {
                                Text(weekdayLabel(for: row))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .frame(height: cellSize)
                            } else {
                                Spacer().frame(height: cellSize)
                            }
                        }
                    }

                    // Month Labels + Grid
                    VStack(alignment: .leading, spacing: 4) {
                        // Month labels
                        HStack(spacing: spacing) {
                            ForEach(0..<columns, id: \.self) { col in
                                let date = getDate(forColumn: col, row: 0)
                                if Calendar.current.component(.weekday, from: date) == 2 {
                                    Text(monthLabel(for: date))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .frame(width: cellSize * 2, alignment: .leading)
                                } else {
                                    Spacer().frame(width: cellSize)
                                }
                            }
                        }

                        // Grid
                        HStack(spacing: spacing) {
                            ForEach(0..<columns, id: \.self) { column in
                                VStack(spacing: spacing) {
                                    ForEach(0..<rows, id: \.self) { row in
                                        let date = getDate(forColumn: column, row: row)
                                        let count = completedTaskCount(for: date)
                                        Rectangle()
                                            .fill(color(for: count))
                                            .frame(width: cellSize, height: cellSize)
                                            .cornerRadius(3)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.white.opacity(0.03), lineWidth: 0.3)
                                            )
                                            .accessibilityLabel("\(count) tasks on \(formattedDate(date))")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Legend
            HStack(spacing: 6) {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.gray)

                ForEach([0, 1, 2, 3, 4], id: \.self) { i in
                    Rectangle()
                        .fill(color(for: i))
                        .frame(width: cellSize, height: cellSize)
                        .cornerRadius(2)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Weekly Bar Chart
            WeeklyBarChartView()
                .environmentObject(taskVM)

            Spacer()
        }
        .background(AppColorPalette.background.ignoresSafeArea())
    }

    // MARK: - Helpers

    func getDate(forColumn column: Int, row: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)

        let daysFromToday = column * 7 + row - (weekday - 1)
        return calendar.date(byAdding: .day, value: -daysFromToday, to: today) ?? today
    }

    func completedTaskCount(for date: Date) -> Int {
        let start = Calendar.current.startOfDay(for: date)
        return taskVM.tasks.filter {
            $0.isCompleted &&
            $0.date != nil &&
            Calendar.current.isDate($0.date!, inSameDayAs: start)
        }.count
    }

    func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.4)
        case 2: return Color.green.opacity(0.6)
        case 3...4: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    func weekdayLabel(for row: Int) -> String {
        switch row {
        case 0: return "Mon"
        case 2: return "Wed"
        case 4: return "Fri"
        default: return ""
        }
    }
}

struct WeeklyBarChartView: View {
    @EnvironmentObject var taskVM: TaskViewModel

    struct DayStat: Identifiable {
        var id = UUID()
        var day: String
        var count: Int
    }

    var data: [DayStat] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }

        return days.map { date in
            let count = taskVM.tasks.filter {
                $0.isCompleted &&
                $0.date != nil &&
                calendar.isDate($0.date!, inSameDayAs: date)
            }.count

            return DayStat(day: weekdayShortName(for: date), count: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)

            Chart(data) {
                BarMark(
                    x: .value("Day", $0.day),
                    y: .value("Completed", $0.count)
                )
                .foregroundStyle(Color.blue)
                .cornerRadius(5)
            }
            .frame(height: 160)
            .padding(.horizontal)
        }
    }

    func weekdayShortName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

#Preview {
    ProgressHeatmapView()
        .environmentObject(TaskViewModel())
}
