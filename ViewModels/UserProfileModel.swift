import Foundation
import UIKit
import Combine

// MARK: - Модель данных профиля

struct UserProfile: Identifiable, Codable {
    var id: String
    var fullName: String
    var nickname: String
    var profession: String
    var email: String
    var avatarJPEGData: Data?   // хранение аватара как Data (jpeg/png)
}

// MARK: - ViewModel профиля

final class UserProfileModel: ObservableObject {
    @Published var profile: UserProfile? {
        didSet { save() }
    }

    private let storageKey = "userProfile.storage.v1"

    init() {
        load()
        // Заполним дефолт, если профиля ещё нет
        if profile == nil {
            profile = UserProfile(
                id: UUID().uuidString,
                fullName: "Pavlo Brodiuk",
                nickname: "pavlo.dev",
                profession: "iOS Developer",
                email: "pavlo.dev@example.com",
                avatarJPEGData: nil
            )
        }
    }

    // MARK: - Утилиты

    /// Текущее изображение аватара как UIImage (геттер/сеттер)
    var avatarImage: UIImage? {
        get {
            guard let data = profile?.avatarJPEGData else { return nil }
            return UIImage(data: data)
        }
        set {
            guard var p = profile else { return }
            p.avatarJPEGData = newValue.flatMap { $0.jpegData(compressionQuality: 0.9) }
            profile = p
        }
    }

    /// Удобный апдейтер (пример: update { $0.nickname = "new" })
    func update(_ mutate: (inout UserProfile) -> Void) {
        guard var p = profile else { return }
        mutate(&p)
        profile = p
    }

    // MARK: - Persistence

    private func save() {
        guard let p = profile else {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        do {
            let data = try JSONEncoder().encode(p)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("UserProfileModel save error:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            profile = try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("UserProfileModel load error:", error)
        }
    }
}
