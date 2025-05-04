import SwiftUI

struct ProjectEditSheetView: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var description: String
    @Binding var comment: String
    @Binding var date: Date
    @Binding var startTime: Date
    @Binding var endTime: Date
    
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
    @State var isPresented = true
    @State var title = "Game Design"
    @State var description = "Create menu in dashboard & Make user flow"
    @State var comment = "Main project screen"
    @State var date = Date()
    @State var startTime = Date()
    @State var endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    let projectIndex = 0

    return ProjectEditSheetView(
        isPresented: $isPresented,
        title: $title,
        description: $description,
        comment: $comment,
        date: $date,
        startTime: $startTime,
        endTime: $endTime,
        projectIndex: projectIndex
    )
    .environmentObject(ProjectViewModel())
}
