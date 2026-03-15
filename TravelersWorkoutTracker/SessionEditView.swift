// SessionEditView.swift
import SwiftData
import SwiftUI

struct SessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\WorkoutTemplate.name)]) private var templates: [WorkoutTemplate]
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]

    @Bindable var session: WorkoutSession

    private var template: WorkoutTemplate? {
        templates.first { $0.id == session.templateId }
    }

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })
    }

    private var orderedEntries: [SessionExercise] {
        if let template {
            var remainingEntries = session.sessionExercises
            var ordered: [SessionExercise] = []

            for entry in template.orderedMovements {
                if let index = remainingEntries.firstIndex(where: { $0.movementId == entry.movementId && $0.equipment == entry.defaultEquipment }) {
                    ordered.append(remainingEntries.remove(at: index))
                }
            }

            ordered.append(contentsOf: remainingEntries)
            return ordered
        }

        return session.sessionExercises
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Date") {
                    DatePicker("Date", selection: $session.date)
                }

                Section("Movements") {
                    ForEach(orderedEntries) { entry in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movementLookup[entry.movementId]?.name ?? "Unknown Movement")
                                .font(.headline)

                            Picker("Equipment", selection: Binding(
                                get: { entry.equipment },
                                set: { entry.equipment = $0 }
                            )) {
                                ForEach(EquipmentType.allCases) { equipment in
                                    Text(equipment.label).tag(equipment)
                                }
                            }
                            .pickerStyle(.menu)

                            HStack(spacing: 10) {
                                intField(title: "Sets", binding: intBinding(for: entry, keyPath: \.sets))
                                intField(title: "Reps", binding: intBinding(for: entry, keyPath: \.reps))
                                intField(title: "Weight", binding: intBinding(for: entry, keyPath: \.weight))
                                intField(title: "RPE", binding: intBinding(for: entry, keyPath: \.rpe))
                            }

                            TextField("Notes", text: notesBinding(for: entry), axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Edit Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func intField(title: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: binding)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .foregroundStyle(.primary)
        }
    }

    private func intBinding(for entry: SessionExercise, keyPath: ReferenceWritableKeyPath<SessionExercise, Int>) -> Binding<String> {
        Binding(
            get: {
                let value = entry[keyPath: keyPath]
                return value == 0 ? "" : String(value)
            },
            set: { newValue in
                entry[keyPath: keyPath] = Int(newValue) ?? 0
            }
        )
    }

    private func notesBinding(for entry: SessionExercise) -> Binding<String> {
        Binding(
            get: { entry.notes ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                entry.notes = trimmed.isEmpty ? nil : newValue
            }
        )
    }
}
