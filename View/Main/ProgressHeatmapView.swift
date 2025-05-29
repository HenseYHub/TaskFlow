import SwiftUI
import Charts

struct ProgressHeatmapView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Circle progress

    private var monthStartDate: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
    }

    private var completedTasksThisMonth: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: monthStartDate)
        return taskVM.tasks.filter { task in
            task.isCompleted && task.date != nil && calendar.isDate(task.date!, inSameDayAs: start) || (task.date != nil && task.date! >= start)
        }.count
    }

    private var totalTasksThisMonth: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: monthStartDate)
        return taskVM.tasks.filter { task in
            task.date != nil && task.date! >= start
        }.count
    }

    // Аналогично для проектов
    private var completedProjectsThisMonth: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: monthStartDate)
        return projectVM.projects.filter { project in
            project.isCompleted &&
            (calendar.isDate(project.date, inSameDayAs: start) || project.date >= start)
        }.count
    }

    private var totalProjectsThisMonth: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: monthStartDate)
        return projectVM.projects.filter { project in
            project.date >= start
        }.count
    }

    @State private var animatedTaskProgress: CGFloat = 0
    @State private var animatedProjectProgress: CGFloat = 0

    private var taskProgress: CGFloat {
        guard totalTasksThisMonth > 0 else { return 0 }
        return CGFloat(completedTasksThisMonth) / CGFloat(totalTasksThisMonth)
    }

    private var projectProgress: CGFloat {
        guard totalProjectsThisMonth > 0 else { return 0 }
        return CGFloat(completedProjectsThisMonth) / CGFloat(totalProjectsThisMonth)
    }

    private let circleSize: CGFloat = 160

    var body: some View {
        VStack(spacing: 32) {
            // MARK: Circle progress with two rings
            ZStack {
                // Внешнее кольцо - проекты (больше радиус)
                Circle()
                    .stroke(Color.purple.opacity(0.2), lineWidth: 16)

                Circle()
                    .trim(from: 0, to: animatedProjectProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.purple, Color.red]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Внутреннее кольцо - задачи (меньше радиус)
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 12)
                    .frame(width: circleSize - 20, height: circleSize - 20)

                Circle()
                    .trim(from: 0, to: animatedTaskProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.blue, Color.cyan]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: circleSize - 20, height: circleSize - 20)
                    .rotationEffect(.degrees(-20))

                // Текст внутри круга — показать прогресс задач и проектов
                VStack(spacing: 6) {
                    Text("\(completedTasksThisMonth)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)

                    Text("Tasks")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Divider().frame(width: 80).background(Color.gray.opacity(0.3))

                    Text("\(completedProjectsThisMonth)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.purple)

                    Text("Projects")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: circleSize, height: circleSize)
            .padding(.top, 24)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    animatedTaskProgress = taskProgress
                    animatedProjectProgress = projectProgress
                }
            }

            WeeklyBarChartView()
                .environmentObject(taskVM)

            Spacer()
        }
        .background(AppColorPalette.background.ignoresSafeArea())
    }

    // MARK: Color helper (reuse from before)
    func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.4)
        case 2: return Color.green.opacity(0.6)
        case 3...4: return Color.green.opacity(0.8)
        default: return Color.green
        }
    }
}

// MARK: WeeklyBarChartView из твоего кода (без изменений)
struct WeeklyBarChartView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @State private var selectedWeekStart: Date = Calendar.current.startOfWeek(for: Date())
    @State private var selectedBar: String? = nil
    @Environment(\.dismiss) private var dismiss

    struct DayStat: Identifiable {
        let id = UUID()
        let day: String
        let count: Int
    }

    var data: [DayStat] {
        let calendar = Calendar.current
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: selectedWeekStart) }

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
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(currentMonth(from: selectedWeekStart))
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            withAnimation {
                                selectedWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: selectedWeekStart) ?? selectedWeekStart
                                selectedBar = nil
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.gray)
                        }

                        Button {
                            withAnimation {
                                selectedWeekStart = Calendar.current.date(byAdding: .day, value: 7, to: selectedWeekStart) ?? selectedWeekStart
                                selectedBar = nil
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)

                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 180)
                    .overlay(
                        Chart(data) { item in
                            BarMark(
                                x: .value("Day", item.day),
                                y: .value("Completed", min(item.count, 5))
                            )
                            .foregroundStyle(Color.blue)
                            .cornerRadius(5)

                            if let selected = selectedBar, selected == item.day {
                                PointMark(
                                    x: .value("Day", item.day),
                                    y: .value("Completed", min(item.count, 5))
                                )
                                .annotation(position: .top) {
                                    Text("Выполнено: \(item.count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color.black.opacity(0.7))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                        .chartYScale(domain: 0...5)
                        .chartYAxis {
                            AxisMarks(values: Array(stride(from: 5, through: 0, by: -1))) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel()
                            }
                        }
                        .chartXAxis {
                            AxisMarks(position: .bottom)
                        }
                        .chartLegend(.hidden)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let chartWidth = UIScreen.main.bounds.width - 40
                                    let x = value.location.x - 20
                                    let index = Int((x / chartWidth) * CGFloat(data.count))
                                    if index >= 0 && index < data.count {
                                        let tappedDay = data[index].day
                                        if selectedBar == tappedDay {
                                            selectedBar = nil
                                        } else {
                                            selectedBar = tappedDay
                                        }
                                    }
                                }
                        )
                        .padding()
                    )
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                dismiss()
            }) {
                Text("Вернуться")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                    .padding(.horizontal)
            }
            .padding(.bottom, 10)
        }
        .background(AppColorPalette.background.ignoresSafeArea())
    }
}

func weekdayShortName(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return formatter.string(from: date)
}

func currentMonth(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: date)
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
    }
}

#Preview {
    ProgressHeatmapView()
        .environmentObject(TaskViewModel())
        .environmentObject(ProjectViewModel()) // Обязательно добавить
}
