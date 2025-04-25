import SwiftUI

struct ProjectInfoSheetView: View {
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Капсула для свайпа
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            // Название
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            // Описание, если есть
            if !description.isEmpty {
                Text(description)
                    .foregroundColor(.white)
            }

            // Дата
            Text("Дата: \(formattedDate(date))")
                .foregroundColor(.white.opacity(0.9))

            // Время
            Text("Час: \(formattedTime(startTime)) – \(formattedTime(endTime))")
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.gray.opacity(0.6))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ProjectInfoSheetView(
        title: "Учёба (Swift)",
        description: "Прохожу SwiftUI",
        date: Date(),
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
    )
}
