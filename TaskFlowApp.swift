import SwiftUI
import Firebase
import FirebaseAuth

@main
struct TaskFlowApp: App {
    @StateObject var taskViewModel = TaskViewModel()
    @StateObject var timerViewModel = TimerViewModel(durationInMinutes: 25)
    @StateObject var userProfile = UserProfileModel()
    @StateObject var projectViewModel = ProjectViewModel()
    @StateObject var authVM = AuthViewModel()
    @StateObject private var lang = LanguageController()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isSignedIn {
                    MainTabView()
                } else {
                    NavigationView { LoginView() }
                }
            }
            // НЕ ставим .id здесь
            .environment(\.locale, lang.locale)
            .environmentObject(lang)
            .environmentObject(taskViewModel)
            .environmentObject(timerViewModel)
            .environmentObject(userProfile)
            .environmentObject(projectViewModel)
            .environmentObject(authVM)
        }
    }
}

