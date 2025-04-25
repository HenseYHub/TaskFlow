import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateTask = false

    @StateObject var taskViewModel = TaskViewModel()
    @StateObject var timerViewModel = TimerViewModel(durationInMinutes: 25)

    var body: some View {
        TabView(selection: $selectedTab) {
            // Главная (Список задач)
            TaskListView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            // Таймер (Фокус)
            if let firstTask = taskViewModel.tasks.first(where: { !$0.isCompleted }) {
                TaskTimerView(
                    timerVM: TimerViewModel(durationInMinutes: firstTask.durationInMinutes),
                    task: firstTask,
                    viewModel: taskViewModel
                )
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(1)
            } else {
                Text("Нет активной задачи")
                    .foregroundColor(.gray)
                    .tabItem {
                        Label("Focus", systemImage: "timer")
                    }
                    .tag(1)
            }

            // Профиль
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)

            // Настройки
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(3)
        }
        .environmentObject(taskViewModel)
    }
}

#Preview {
    MainTabView()
        .environment(\.colorScheme, .dark)
}
