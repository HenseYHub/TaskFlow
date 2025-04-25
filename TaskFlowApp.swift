import SwiftUI

@main
struct TaskFlowApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var userProfile = UserProfileModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(taskViewModel)
                .environmentObject(userProfile)
        }
    }
}
