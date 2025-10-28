import SwiftUI

final class LanguageController: ObservableObject {
    @Published var appLanguage: String {
        didSet { setLocale(appLanguage) }
    }
    @Published var locale: Locale

    init() {
        let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.appLanguage = saved
        self.locale = Locale(identifier: saved)
        setLocale(saved, persist: false)
    }

    private func setLocale(_ code: String, persist: Bool = true) {
        // обновляем локаль (это дернёт перерисовку всех String(localized:))
        DispatchQueue.main.async { [weak self] in
            self?.locale = Locale(identifier: code)
        }
        if persist {
            UserDefaults.standard.set(code, forKey: "appLanguage")
        }
    }
}
