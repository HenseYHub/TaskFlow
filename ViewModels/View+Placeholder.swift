//
//  View+Placeholder.swift
//  TaskFlow
//
//  Created by Pavlo on 04.08.2025.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder().padding(.horizontal, 12)
            }
            self
        }
    }
}

