import SwiftUI

@main
struct TaskFlowApp: App {
    @StateObject var taskViewModel = TaskViewModel()
    @StateObject var timerViewModel = TimerViewModel(durationInMinutes: 25)
    @StateObject var userProfile = UserProfileModel()
    @StateObject var projectViewModel = ProjectViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(taskViewModel)
                .environmentObject(timerViewModel)
                .environmentObject(userProfile)
                .environmentObject(projectViewModel)
        }
    }
}
