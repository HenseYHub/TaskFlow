import SwiftUI

struct ProjectInfoSheetView: View {
    var title: String
    var description: String
    var date: Date
    var startTime: Date
    var endTime: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)

            if !description.isEmpty {
                Text(description)
                    .foregroundColor(.white)
            }

            Text("Date: \(formattedDate(date))")
                .foregroundColor(.white.opacity(0.9))

            Text("Time: \(formattedTime(startTime)) – \(formattedTime(endTime))")
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
        title: "Demo Project",
        description: "Project description",
        date: Date(),
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .minute, value: 60, to: Date()) ?? Date()
    )
}
