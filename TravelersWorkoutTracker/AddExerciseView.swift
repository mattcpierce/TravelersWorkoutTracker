// AddExerciseView.swift
import SwiftData
import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var descriptionText = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Movement") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Add Movement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMovement() }
                }
            }
        }
    }

    private func saveMovement() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Name is required."
            return
        }

        let slug = trimmed.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "_")
        let id = "\(slug)_\(UUID().uuidString.prefix(8))"
        let movement = Movement(id: id, name: trimmed, description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines))
        modelContext.insert(movement)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(for: [Movement.self], inMemory: true)
}
