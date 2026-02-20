//
//  AboutDevelopmentView.swift
//  TaskFlow
//
//  Created by Pavlo on 06.01.2026.
//

import SwiftUI

struct AboutDevelopmentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStringKey("about_dev_title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(LocalizedStringKey("about_dev_text"))
                    .foregroundColor(.gray)
                
                Divider().overlay(Color.white.opacity(0.12))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey("about_dev_stack_title"))
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer(minLength: 16)
            }
            .padding()
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .navigationTitle(LocalizedStringKey("settings_about_development"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AboutDevelopmentView()
}
