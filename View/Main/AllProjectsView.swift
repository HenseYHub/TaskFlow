import SwiftUI

struct AllProjectsView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var selectedProjectIndex: Int?
    @State private var showProjectInfo: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("All Projects")
                .font(.largeTitle.bold())
                .padding()
                .foregroundColor(.white)

            if projectViewModel.projects.isEmpty {
                Spacer()
                Text("У вас еще нет проектов")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(projectViewModel.projects.indices, id: \.self) { index in
                            let project = projectViewModel.projects[index]

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(project.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                }

                                Text(project.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Text(project.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text("\(formattedTime(project.startTime)) – \(formattedTime(project.endTime))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                    .padding()
                }
            }
        }
        .background(AppColorPalette.background.ignoresSafeArea())
        .sheet(isPresented: $showProjectInfo) {
            if let index = selectedProjectIndex, index < projectViewModel.projects.count {
                let project = projectViewModel.projects[index]
                ProjectInfoSheetView(
                    title: project.title,
                    description: project.description,
                    date: project.date,
                    startTime: project.startTime,
                    endTime: project.endTime
                )
                .presentationDetents([.height(220)])
                .presentationBackground(.clear)
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    AllProjectsView()
        .environmentObject(ProjectViewModel())
}
