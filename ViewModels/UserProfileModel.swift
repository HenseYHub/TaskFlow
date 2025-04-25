//
//  UserProfileModel.swift
//  TaskFlow
//
//  Created by Pavlo on 24.04.2025.
//

import SwiftUI

class UserProfileModel: ObservableObject {
    @Published var fullName: String = "Pavlo Brodiuk"
    @Published var nickname: String = "pavlo.dev"
    @Published var profession: String = "iOS Developer"
    @Published var email: String = "pavlo.dev@example.com"
    @Published var password: String = "password123"
    @Published var avatarImage: UIImage? = nil
}
