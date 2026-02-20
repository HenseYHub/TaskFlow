import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreateTask = false

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var timerViewModel: TimerViewModel
    @EnvironmentObject var userProfile: UserProfileModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var lang: LanguageController   // ✅ добавили

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColorPalette.background)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack {
            
            AppColorPalette.background
                .ignoresSafeArea(.all, edges: .all)

            TabView(selection: $selectedTab) {

                // HOME
                NavigationStack {
                    DailyTimelineView()
                        .environmentObject(taskViewModel)
                        .environmentObject(userProfile)
                        .environmentObject(projectViewModel)
                }
                .tabItem { Label(LocalizedStringKey("tab_home"), systemImage: "house") }
                .tag(0)

                // FOCUS
                NavigationStack {
                    FocusView()
                        .environmentObject(timerViewModel)
                }
                .tabItem { Label(LocalizedStringKey("tab_focus"), systemImage: "timer") }
                .tag(1)

                // пустой таб под "+"
                Color.clear
                    .tabItem { Image(systemName: "") }
                    .tag(2)

                // PROFILE
                NavigationStack {
                    ProfileView()
                        .environmentObject(taskViewModel)
                        .environmentObject(authVM)
                        .environmentObject(userProfile)
                        .environmentObject(projectViewModel)
                }
                .tabItem { Label(LocalizedStringKey("tab_profile"), systemImage: "person.crop.circle") }
                .tag(3)

                // SETTINGS
                NavigationStack {
                    SettingsView()
                        .environmentObject(lang) // ✅ SettingsView использует LanguageController
                }
                .tabItem { Label(LocalizedStringKey("tab_settings"), systemImage: "gearshape") }
                .tag(4)
            }
            // ✅ вот это главное для твоей проблемы:
            .environment(\.locale, lang.locale)   // форсим локаль на весь TabView
            .id(lang.appLanguage)                 // пересоздаём TabView при смене языка

            // центральная кнопка "+"
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showCreateTask = true }) {
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
        .onAppear {
            Task {
                await NotificationScheduler.shared.hardTestIn15Seconds()
            }
        }

    }
    
}


#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(TaskViewModel())
        .environmentObject(TimerViewModel(durationInMinutes: 25))
        .environmentObject(UserProfileModel())
        .environmentObject(ProjectViewModel())
        .environmentObject(LanguageController()) // ✅ важно для превью
        .environment(\.colorScheme, .dark)
}
