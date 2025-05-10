import SwiftUI

struct DailyTimelineView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @State private var selectedDate: Date = Date()
    @State private var selectedTaskID: UUID? = nil

    var filteredTasks: [TaskModel] {
        let sameDayTasks = taskViewModel.tasks.filter {
            guard let taskDate = $0.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
        }

        return sameDayTasks.sorted {
            ($0.startTime ?? Date()) < ($1.startTime ?? Date())
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedFullDate(selectedDate))
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("Today")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        } else {
                            Text(formattedWeekday(selectedDate))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    if let image = userProfile.avatarImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)

                // MARK: Calendar Scroll
                // ...

                // MARK: Calendar Scroll
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<14) { offset in
                                let date = Calendar.current.date(byAdding: .day, value: offset - 7, to: Date()) ?? Date()
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                                VStack(spacing: 6) {
                                    Text(dayNumber(date))
                                        .font(.headline)
                                    Text(shortWeekday(date))
                                        .font(.caption2)

                                    // Точка под датой
                                    Circle()
                                        .fill(isSelected ? .black : .gray)
                                        .frame(width: 6, height: 6)
                                        .opacity(isSelected ? 1 : (hasTasks(on: date) ? 1 : 0))
                                }
                                .frame(width: 44, height: 90)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(isSelected ? Color.white : Color.clear)
                                )
                                .foregroundColor(isSelected ? .black : .gray)
                                .id(offset)
                                .onTapGesture {
                                    withAnimation {
                                        selectedDate = date
                                        proxy.scrollTo(offset, anchor: .center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .onAppear {
                        let todayIndex = 7
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(todayIndex, anchor: .center)
                            }
                        }
                    }
                }

            }
            .padding(.top)

            // MARK: Timeline
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                                    .background(
                                        Circle().fill(selectedTaskID == task.id ? Color.white : Color.black)
                                    )
                                    .frame(width: 14, height: 14)

                                if index < filteredTasks.count - 1 {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 70)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(task.name)
                                        .font(.headline)
                                        .foregroundColor(task.isCompleted ? .gray : .white)
                                        .strikethrough(task.isCompleted)

                                    Spacer()

                                    if let start = task.startTime, let end = task.endTime {
                                        Text("\(formattedTime(start))–\(formattedTime(end))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                if let comment = task.comment, !comment.isEmpty {
                                    Text(comment)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                if selectedTaskID == task.id {
                                    Button(action: {
                                        withAnimation {
                                            taskViewModel.toggleTaskCompletion(task: task)
                                            if let nextTask = filteredTasks.first(where: { $0.id != task.id && !$0.isCompleted }) {
                                                selectedTaskID = nextTask.id
                                            }
                                        }
                                    }) {
                                        Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                                            .foregroundColor(task.isCompleted ? .green : .gray)
                                            .font(.title2)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                            .padding()
                            .background(selectedTaskID == task.id ? Color.white.opacity(0.05) : Color.clear)
                            .cornerRadius(20)
                            .onTapGesture {
                                withAnimation {
                                    selectedTaskID = task.id
                                }
                            }
                        }
                    }

                    if filteredTasks.isEmpty {
                        Text("Немає задач на цей день")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
    }

    // MARK: Helpers

    func hasTasks(on date: Date) -> Bool {
        taskViewModel.tasks.contains {
            Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
        }
    }

    func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    func formattedFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    func formattedWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    DailyTimelineView()
        .environmentObject(TaskViewModel())
        .environmentObject(UserProfileModel())
}
