import SwiftUI

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .gray)

                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(height: 2)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
