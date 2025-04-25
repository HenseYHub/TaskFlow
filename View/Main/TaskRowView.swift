//
//  TaskRowView.swift
//  TaskFlow
//
//  Created by Pavlo on 22.04.2025.
//

import SwiftUI

struct TaskRowView: View {
    let task: TaskModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(task.durationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let date = task.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    TaskRowView(task: TaskModel.sample)
}

