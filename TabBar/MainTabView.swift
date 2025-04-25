import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateTask = false

    // Заменим на @EnvironmentObject
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var timerViewModel: TimerViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TaskListView()
            }
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
        .environmentObject(timerViewModel)
    }
}

#Preview {
    MainTabView()
        .environmentObject(TaskViewModel())
        .environmentObject(TimerViewModel(durationInMinutes: 25))
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
        .environment(\.colorScheme, .dark)
}



