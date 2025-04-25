//
//  RoundedCorner.swift
//  TaskFlow
//
//  Created by Pavlo on 24.04.2025.
//

import Foundation
import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = 30
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
