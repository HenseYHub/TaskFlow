import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateTask = false

    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var timerViewModel: TimerViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectViewModel: ProjectViewModel

    init() {
        // Настройка фона TabBar через UIKit
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColorPalette.background) // кастомный цвет
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack {
            AppColorPalette.background
                        .ignoresSafeArea(.all, edges: .all)
            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $selectedTab) {
                    NavigationStack {
                        TaskListView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)

                    DailyTimelineView()
                        .environmentObject(taskViewModel)
                        .tabItem {
                            Label("Focus", systemImage: "timer")
                        }
                        .tag(1)


                    // Пустой таб для размещения кнопки "+"
                    Color.clear
                        .tabItem {
                            Image(systemName: "")
                        }
                        .tag(2)

                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(3)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .tag(4)
                }
            }

            // Кнопка "+" по центру
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showCreateTask = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.gray.opacity(0.6), radius: 4, x: 0, y: 2)
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.system(size: 28, weight: .bold))
                        }
                    }
                    .offset(y: -10)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showCreateTask) {
            CreateNewTaskView()
                .environmentObject(taskViewModel)
                .environmentObject(timerViewModel)
                .environmentObject(userProfile)
                .environmentObject(projectViewModel)
        }
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
