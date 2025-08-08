import SwiftUI

struct ProjectEditSheetView: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var description: String
    @Binding var comment: String
    @Binding var date: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var isCompleted: Bool   // <-- добавлено
    
    var projectIndex: Int
    
    @EnvironmentObject var projectViewModel: ProjectViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Edit Project")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 12)

                TextField("Project Title", text: $title)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                TextField("Description", text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                TextField("Comment", text: $comment)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .foregroundColor(.white)

                HStack {
                    Text("Date")
                        .foregroundColor(.white)
                    Spacer()
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .colorScheme(.dark)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Start")
                            .foregroundColor(.white)
                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("End")
                            .foregroundColor(.white)
                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                }

                // Добавляем переключатель "Выполнено"
                Toggle(isOn: $isCompleted) {
                    Text("Completed")
                        .foregroundColor(.white)
                }
                .padding()

                Spacer()

                Button(action: {
                    guard projectIndex < projectViewModel.projects.count else {
                        print("Invalid project index!")
                        return
                    }

                    let updatedProject = ProjectModel(
                        id: projectViewModel.projects[projectIndex].id,
                        title: title,
                        description: description,
                        comment: comment,
                        date: date,
                        startTime: startTime,
                        endTime: endTime
                    )

                    projectViewModel.updateProject(at: projectIndex, with: updatedProject)
                    isPresented = false
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.bottom, 16)
            }
            .padding()
        }
        .presentationCornerRadius(24)
    }
}



#Preview {
    ProjectEditSheetViewPreviewWrapper()
}

private struct ProjectEditSheetViewPreviewWrapper: View {
    @State private var isPresented = true
    @State private var title = "Game Design"
    @State private var description = "Create menu in dashboard & Make user flow"
    @State private var comment = "Main project screen"
    @State private var date = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var isCompleted = false

    var body: some View {
        ProjectEditSheetView(
            isPresented: $isPresented,
            title: $title,
            description: $description,
            comment: $comment,
            date: $date,
            startTime: $startTime,
            endTime: $endTime,
            isCompleted: $isCompleted,
            projectIndex: 0
        )
        .environmentObject(ProjectViewModel())
    }
}
