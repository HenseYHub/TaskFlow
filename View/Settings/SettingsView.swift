import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var lang: LanguageController
    @State private var notificationsOn = true

    private let languages: [(code: String, name: String)] = [
        ("uk", "Українська"), ("en", "English"), ("de", "Deutsch")
    ]

    var body: some View {
        List {
            Section(header: Text(LocalizedStringKey("settings_notifications_header"))) {
                Toggle(LocalizedStringKey("settings_notifications_allow"), isOn: $notificationsOn)
            }

            Section(header: Text(LocalizedStringKey("settings_language_header"))) {
                Picker(LocalizedStringKey("settings_language_picker_title"), selection: $lang.appLanguage) {
                    ForEach(languages, id: \.code) { item in
                        Text(item.name).tag(item.code)
                    }
                }
            }


            Section(header: Text(LocalizedStringKey("settings_privacy_header"))) {
                NavigationLink(LocalizedStringKey("settings_data_manage")) {
                    Text(LocalizedStringKey("settings_data_placeholder"))
                        .padding()
                }
            }

            Section(header: Text(LocalizedStringKey("settings_about_header"))) {
                HStack {
                    Text(LocalizedStringKey("settings_version"))
                    Spacer()
                    Text(appVersionString).foregroundColor(.gray)
                }
                NavigationLink(LocalizedStringKey("settings_about_development")) {
                    Text(LocalizedStringKey("settings_about_text"))
                        .padding()
                }
            }
        }
        .navigationTitle(Text(LocalizedStringKey("settings_title")))
        .scrollContentBackground(.hidden)
        .background(AppColorPalette.background)
        .environment(\.locale, lang.locale)   // ← форсим локаль для экрана
        .id(lang.appLanguage)                 // ← принудительный ре-рендер
    }

    private var appVersionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}


#Preview {
    NavigationStack { SettingsView() } // оборачиваем только для превью
        .environmentObject(LanguageController())
}
