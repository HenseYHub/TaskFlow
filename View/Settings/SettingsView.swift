import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var lang: LanguageController
    @StateObject private var notificationManager = NotificationManager()

    // ✅ 저장/настройка lead time (за сколько минут)
    @AppStorage("remindLeadMinutes") private var remindLeadMinutes: Int = 10
    private let leadOptions: [Int] = [0, 5, 10, 15, 30, 60]

    // Alerts
    @State private var showNotifDeniedAlert = false
    @State private var showNotifResultAlert = false
    @State private var notifResultTitleKey: LocalizedStringKey = "reset_password_sent_title"
    @State private var notifResultMessageKey: LocalizedStringKey = "settings_notifications_result_enabled"

    private let languages: [(code: String, name: String)] = [
        ("uk", "Українська"),
        ("en", "English"),
        ("de", "Deutsch")
    ]

    var body: some View {
        List {
            // MARK: Notifications
            Section(header: Text(LocalizedStringKey("settings_notifications_header"))) {

                Toggle(
                    LocalizedStringKey("settings_notifications_allow"),
                    isOn: Binding(
                        get: { notificationManager.status.isEnabled },
                        set: { newValue in
                            Task { await handleNotificationsToggle(newValue) }
                        }
                    )
                )

                // ✅ Выбор времени напоминания
                Picker(LocalizedStringKey("settings_notifications_lead_time"), selection: $remindLeadMinutes) {
                    ForEach(leadOptions, id: \.self) { m in
                        Text(leadLabel(m)).tag(m)
                    }
                }
                .disabled(!notificationManager.status.isEnabled)
                .opacity(notificationManager.status.isEnabled ? 1 : 0.5)
            }

            // MARK: Language
            Section(header: Text(LocalizedStringKey("settings_language_header"))) {
                Picker(
                    LocalizedStringKey("settings_language_picker_title"),
                    selection: $lang.appLanguage
                ) {
                    ForEach(languages, id: \.code) { item in
                        Text(item.name).tag(item.code)
                    }
                }

                Button {
                    notificationManager.openAppSettings()
                } label: {
                    HStack {
                        Text(LocalizedStringKey("settings_open_app_settings"))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.gray)
                    }
                }
            }

            // MARK: Data & Privacy
            Section(header: Text(LocalizedStringKey("settings_privacy_header"))) {
                NavigationLink(LocalizedStringKey("settings_data_manage")) {
                    DataManagementView()
                }
            }

            // MARK: About
            Section(header: Text(LocalizedStringKey("settings_about_header"))) {
                HStack {
                    Text(LocalizedStringKey("settings_version"))
                    Spacer()
                    Text(appVersionString)
                        .foregroundColor(.gray)
                }

                NavigationLink(LocalizedStringKey("settings_about_development")) {
                    AboutDevelopmentView()
                }
            }
        }
        .navigationTitle(LocalizedStringKey("setting_title"))
        .scrollContentBackground(.hidden)
        .background(AppColorPalette.background)
        .task { await notificationManager.refreshStatus() }
        .onAppear { Task { await notificationManager.refreshStatus() } }

        // denied alert
        .alert(LocalizedStringKey("settings_notifications_denied_title"), isPresented: $showNotifDeniedAlert) {
            Button(LocalizedStringKey("settings_open_settings")) {
                notificationManager.openAppSettings()
            }
            Button(LocalizedStringKey("common_cancel"), role: .cancel) { }
        } message: {
            Text(LocalizedStringKey("settings_notifications_denied_message"))
        }

        // result alert
        .alert(notifResultTitleKey, isPresented: $showNotifResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notifResultMessageKey)
        }
    }

    // MARK: - Helpers

    private func leadLabel(_ minutes: Int) -> String {
        if minutes == 0 {
            return String(localized: "settings_notifications_lead_at_start", defaultValue: "At start")
        } else {
            let format = String(localized: "settings_notifications_lead_minutes_format",
                                defaultValue: "%d min before")
            return String(format: format, minutes)
        }
    }

    private func handleNotificationsToggle(_ wantOn: Bool) async {
        await notificationManager.refreshStatus()

        if wantOn {
            switch notificationManager.status {
            case .notDetermined:
                let granted = await notificationManager.requestAuthorization()
                notifResultTitleKey = "settings_notifications_result_title"
                notifResultMessageKey = granted
                    ? "settings_notifications_result_enabled"
                    : "settings_notifications_result_not_enabled"
                showNotifResultAlert = true

            case .denied:
                showNotifDeniedAlert = true

            default:
                notifResultTitleKey = "settings_notifications_result_title"
                notifResultMessageKey = "settings_notifications_result_enabled"
                showNotifResultAlert = true
            }
        } else {
            // iOS не дает программно выключить permissions — ведем в настройки
            showNotifDeniedAlert = true
        }
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    let lang = LanguageController()

    return NavigationStack {
        SettingsView()
            .environmentObject(lang)
    }
    .environment(\.locale, lang.locale)
    .id(lang.appLanguage)
}
