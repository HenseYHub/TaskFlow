import SwiftUI

struct DailyTimelineView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @AppStorage("profileImageData") private var profileImageData: Data?
    @Environment(\.locale) private var locale
    
    // MARK: - Edit sheet state
    @State private var editingTask: TaskModel?
    @State private var tempDate: Date = Date()
    @State private var tempStartTime: Date = Date()
    @State private var tempEndTime: Date = Date()
    @State private var tempName: String = ""
    @State private var tempComment: String = ""

    // MARK: - Other state
    @State private var showDatePickerInline = false
    @State private var showCreateProjectView = false
    @State private var selectedDate: Date = Date()
    @State private var selectedTaskID: UUID? = nil

    private var hasProjects: Bool { !projectViewModel.projects.isEmpty }

    // tasks for the selected date
    var filteredTasks: [TaskModel] {
        let sameDayTasks = taskViewModel.tasks.filter {
            guard let taskDate = $0.date else { return false }
            return Calendar.current.isDate(taskDate, inSameDayAs: selectedDate)
        }
        return sameDayTasks.sorted { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizedFullDate(selectedDate))
                            .foregroundColor(.gray)
                            .font(.subheadline)

                        if Calendar.current.isDateInToday(selectedDate) {
                            Text("today_title")
                                .font(.title.bold())
                                .foregroundColor(.white)
                        } else {
                            Text(localizedWeekdayWide(selectedDate))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    if let data = profileImageData,
                       let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)

                // MARK: Calendar Scroll (2 weeks)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<14) { offset in
                                let date = Calendar.current.date(
                                    byAdding: .day,
                                    value: offset - 7,
                                    to: Date()
                                ) ?? Date()
                                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)

                                VStack(spacing: 6) {
                                    Text(dayNumber(date))
                                        .font(.headline)

                                    Text(weekdayAbbrev(date))
                                        .font(.caption2)

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

            // MARK: Tasks list
            List {
                Section {
                    ForEach(filteredTasks) { task in
                        HybridTaskRow(task: task) {
                            withAnimation {
                                taskViewModel.toggleTaskCompletion(task: task)
                            }
                        }
                        .onTapGesture {
                            openEditor(for: task)
                        }
                        // swipe RIGHT → move to tomorrow
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    taskViewModel.moveTask(task, byDays: 1)
                                }
                            } label: {
                                Label("Tomorrow", systemImage: "arrow.right.circle")

                            }
                        }
                        // swipe LEFT → delete
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    taskViewModel.deleteTask(task)
                                }
                            } label: {
                                Label("delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    if filteredTasks.isEmpty {
                        Text("no_tasks_for_day")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .animation(.easeInOut, value: hasProjects)
        .fullScreenCover(isPresented: $showCreateProjectView) {
            CreateNewTaskView()
                .environmentObject(taskViewModel)
                .environmentObject(projectViewModel)
                .environmentObject(userProfile)
        }
        .sheet(
            isPresented: Binding(
                get: { editingTask != nil },
                set: { if !$0 { editingTask = nil } }
            )
        ) {
            if let task = editingTask {
                editPanel(task: task)
                    .presentationDetents([.fraction(0.72)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(AppColorPalette.background)
            }
        }
    }

    // MARK: - Editor logic

    private func openEditor(for task: TaskModel) {
        editingTask = task

        let baseDate = task.date ?? selectedDate
        tempDate = baseDate
        tempStartTime = task.startTime ?? baseDate

        let defaultEnd = (task.startTime ?? baseDate)
            .addingTimeInterval(TimeInterval(task.durationInMinutes * 60))
        tempEndTime = task.endTime ?? defaultEnd

        tempName = task.name
        tempComment = task.comment ?? ""
        
        // при открытии редактора прячем только календарь
        showDatePickerInline = false
    }

    @ViewBuilder
    private func editPanel(task: TaskModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // маленький “хэндл”
                Capsule()
                    .frame(width: 40, height: 4)
                    .foregroundColor(.gray.opacity(0.08))

                // HEADER
                HStack {
                    Text("edit_task_title")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        editingTask = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gray)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                }

                // NAME + COMMENT CARD
                VStack(alignment: .leading, spacing: 10) {
                    Text("task_name_label")
                        .font(.caption)
                        .foregroundColor(.gray)

                    TextField("task_name_placeholder", text: $tempName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                        )
                        .foregroundColor(.white)

                    Text("task_description_label")
                        .font(.caption)
                        .foregroundColor(.gray)

                    TextField(
                        "task_description_placeholder",
                        text: $tempComment,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06))
                    )
                    .foregroundColor(.white)
                    .lineLimit(2...4)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )

                // DATE + TIME CARD
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("task_datetime_section_title")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Spacer()

                        Text(task.durationText)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    // DATE (chip + icon)
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDatePickerInline.toggle()
                            }
                        } label: {
                            Text(formattedChipDate(tempDate))
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.10))
                                )
                        }

                        Spacer(minLength: 0)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showDatePickerInline.toggle()
                            }
                        } label: {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.18))
                                )
                        }
                    }

                    if showDatePickerInline {
                        DatePicker(
                            "",
                            selection: $tempDate,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .tint(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.04))
                        )
                        .transition(.opacity)
                    }

                    Divider()
                        .overlay(Color.white.opacity(0.12))

                    // TIME – как в CreateNewTaskView: два ползунка рядом
                    VStack(alignment: .leading, spacing: 8) {
                        Text("task_time_section_label")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 16) {
                            // START
                            DatePicker(
                                "",
                                selection: $tempStartTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .colorMultiply(.white)
                            .preferredColorScheme(.dark)

                            Text("-")
                                .foregroundColor(.white)

                            // END (не раньше старта и до конца дня)
                            DatePicker(
                                "",
                                selection: $tempEndTime,
                                in: tempStartTime...endOfEditDay(),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .colorMultiply(.white)
                            .preferredColorScheme(.dark)

                            Spacer(minLength: 0)

                            Image(systemName: "clock")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                )

                // BUTTONS
                HStack(spacing: 12) {
                    Button("common_cancel") {
                        editingTask = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                    )
                    .foregroundColor(.white)

                    Button("common_save") {
                        taskViewModel.updateTaskTime(
                            task: task,
                            newDate: tempDate,
                            newStart: tempStartTime,
                            newEnd: tempEndTime
                        )
                        taskViewModel.updateTaskMeta(
                            task,
                            name: tempName,
                            comment: tempComment.isEmpty ? nil : tempComment
                        )
                        editingTask = nil
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.18))
                    )
                    .foregroundColor(.white)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        // следим, чтобы endTime не уезжал раньше старта и не выходил за конец дня
        .onChange(of: tempStartTime) { _ in clampEditEndTime() }
        .onChange(of: tempDate) { _ in clampEditEndTime() }
        .onChange(of: tempEndTime) { _ in clampEditEndTime() }
    }

    // MARK: Helpers (locale-aware + time helpers)

    private func hasTasks(on date: Date) -> Bool {
        taskViewModel.tasks.contains {
            Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
        }
    }

    private func dayNumber(_ date: Date) -> String {
        date.formatted(.dateTime.day().locale(locale))
    }

    private func weekdayAbbrev(_ date: Date) -> String {
        let symbols = localizedShortWeekdaySymbols(for: locale)
        var cal = Calendar.current
        cal.locale = locale
        let idx = cal.component(.weekday, from: date) - 1
        let safeIndex = max(0, min(idx, symbols.count - 1))
        return symbols[safeIndex]
    }

    private func localizedFullDate(_ date: Date) -> String {
        date.formatted(
            .dateTime.month(.wide).day().year().locale(locale)
        )
    }

    private func localizedWeekdayWide(_ date: Date) -> String {
        date.formatted(
            .dateTime.weekday(.wide).locale(locale)
        )
    }

    private func localizedShortWeekdaySymbols(for locale: Locale) -> [String] {
        let df = DateFormatter()
        df.locale = locale

        if let syms = df.shortWeekdaySymbols, !syms.isEmpty {
            return syms
        }
        if let full = df.weekdaySymbols, !full.isEmpty {
            return full
        }
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private func formattedChipDate(_ date: Date) -> String {
        date.formatted(
            .dateTime.day().month().year().locale(locale)
        )
    }
    
    private func formattedChipTime(_ date: Date) -> String {
        date.formatted(
            .dateTime.hour().minute().locale(locale)
        )
    }

    // конец дня для редактируемой даты
    private func endOfEditDay() -> Date {
        let cal = Calendar.current
        return cal.date(
            bySettingHour: 23,
            minute: 59,
            second: 0,
            of: tempDate
        ) ?? tempDate
    }

    // не даём endTime стать раньше startTime и позже конца дня
    private func clampEditEndTime() {
        let cal = Calendar.current

        if tempEndTime < tempStartTime {
            tempEndTime = cal.date(
                byAdding: .minute,
                value: 30,
                to: tempStartTime
            ) ?? tempStartTime
        }

        let endDay = endOfEditDay()
        if tempEndTime > endDay {
            tempEndTime = endDay
        }
    }
}

#if DEBUG
#Preview {
    let profile = UserProfileModel()
    profile.profile = UserProfile(
        id: "preview",
        fullName: "Pasha",
        nickname: "pavlo.dev",
        profession: "iOS Dev",
        email: "p@example.com",
        avatarJPEGData: nil
    )

    return DailyTimelineView()
        .environmentObject(TaskViewModel())
        .environmentObject(profile)
        .environmentObject(ProjectViewModel())
        .environment(\.locale, Locale(identifier: "en"))
}
#endif

// MARK: - Hybrid row (left date rail + task card)

private struct HybridTaskRow: View {
    @Environment(\.locale) private var locale
    let task: TaskModel
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left date rail
            VStack(alignment: .leading, spacing: 2) {
                Text(weekdayShort(task.date))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(dayNumber(task.date))
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 46, alignment: .leading)

            // Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .strikethrough(task.isCompleted)

                    Spacer()

                    if let s = task.startTime, let e = task.endTime {
                        Text("\(time(s))–\(time(e))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                if let c = task.comment, !c.isEmpty {
                    Text(c)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Button(action: onToggle) {
                    Label(
                        task.isCompleted
                        ? String(localized: "marked_completed",
                                 defaultValue: "Marked as completed")
                        : String(localized: "mark_completed",
                                 defaultValue: "Mark as completed"),
                        systemImage: task.isCompleted ? "checkmark.square.fill" : "square"
                    )
                    .font(.footnote)
                    .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .padding(.top, 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08))
            )
        }
        .contentShape(Rectangle())
    }

    // local helpers (locale-aware)
    private func dayNumber(_ date: Date?) -> String {
        (date ?? Date()).formatted(.dateTime.day().locale(locale))
    }

    private func weekdayShort(_ date: Date?) -> String {
        let d = date ?? Date()
        let symbols = localizedShortWeekdaySymbols(for: locale)
        var cal = Calendar.current
        cal.locale = locale
        let idx = cal.component(.weekday, from: d) - 1
        let safeIndex = max(0, min(idx, symbols.count - 1))
        return symbols[safeIndex]
    }

    private func time(_ d: Date) -> String {
        d.formatted(.dateTime.hour().minute().locale(locale))
    }

    private func localizedShortWeekdaySymbols(for locale: Locale) -> [String] {
        let df = DateFormatter()
        df.locale = locale
        if let syms = df.shortWeekdaySymbols, !syms.isEmpty {
            return syms
        }
        if let full = df.weekdaySymbols, !full.isEmpty {
            return full
        }
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
}

// MARK: - ViewModel helpers for swipe actions

extension TaskViewModel {
    func deleteTask(_ task: TaskModel) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: idx)
        }
    }

    func updateTaskMeta(_ task: TaskModel, name: String, comment: String?) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].name = name
        tasks[idx].comment = comment
    }

    func moveTask(_ task: TaskModel, byDays days: Int = 1) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let cal = Calendar.current
        if let d = tasks[idx].date {
            tasks[idx].date = cal.date(byAdding: .day, value: days, to: d)
        }
        if let s = tasks[idx].startTime {
            tasks[idx].startTime = cal.date(byAdding: .day, value: days, to: s)
        }
        if let e = tasks[idx].endTime {
            tasks[idx].endTime = cal.date(byAdding: .day, value: days, to: e)
        }
    }
}
