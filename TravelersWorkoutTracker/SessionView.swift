// SessionView.swift
import SwiftData
import SwiftUI

struct SessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\WorkoutTemplate.name)]) private var templates: [WorkoutTemplate]
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var allSessions: [WorkoutSession]

    let session: WorkoutSession
    @State private var saveErrorMessage: String?

    private var template: WorkoutTemplate? {
        templates.first { $0.id == session.templateId }
    }

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })
    }

    private var orderedEntries: [SessionExercise] {
        guard let template else { return session.sessionExercises }

        var remaining = session.sessionExercises
        var ordered: [SessionExercise] = []

        for templateEntry in template.orderedMovements {
            if let index = remaining.firstIndex(where: {
                $0.movementId == templateEntry.movementId && $0.equipment == templateEntry.defaultEquipment
            }) {
                ordered.append(remaining.remove(at: index))
            }
        }

        ordered.append(contentsOf: remaining)
        return ordered
    }

    private var canFinish: Bool {
        !orderedEntries.isEmpty && orderedEntries.allSatisfy { $0.rpe >= 6 && $0.rpe <= 10 }
    }

    var body: some View {
        List {
            if orderedEntries.isEmpty {
                Text("This session has no movements.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(orderedEntries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movementLookup[entry.movementId]?.name ?? "Unknown Movement")
                                    .font(.headline)

                                if let description = movementLookup[entry.movementId]?.description,
                                   !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(description)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                entry.isCompleted = true
                                saveContext()
                            } label: {
                                if entry.isCompleted {
                                    Label("Completed", systemImage: "checkmark.circle.fill")
                                } else {
                                    Text("Complete")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(entry.isCompleted ? .green : .accentColor)
                        }

                        EquipmentPickerView(
                            title: "Equipment",
                            options: EquipmentType.allCases,
                            selection: Binding(
                                get: { entry.equipment },
                                set: { newValue in
                                    entry.equipment = newValue
                                }
                            )
                        )

                        if let previous = lastTimeEntry(for: entry) {
                            Text("Last time: \(SessionHistoryLookup.summaryText(for: previous))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 10) {
                            field(title: "Sets", text: intBinding(for: entry, keyPath: \.sets))
                            field(title: "Reps", text: intBinding(for: entry, keyPath: \.reps))
                            field(title: "Weight", text: intBinding(for: entry, keyPath: \.weight))
                        }

                        SegmentedRPEPicker(selectedRPE: Binding(
                            get: { (6...10).contains(entry.rpe) ? entry.rpe : nil },
                            set: { newValue in
                                entry.rpe = newValue ?? 0
                            }
                        ))

                        if !(6...10).contains(entry.rpe) {
                            Text("RPE not set")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        TextField("Optional notes", text: notesBinding(for: entry), axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)

                        Button("Use Last Time") {
                            useLastTime(for: entry)
                        }
                        .buttonStyle(.bordered)
                        .disabled(lastTimeEntry(for: entry) == nil)
                    }
                    .padding(.vertical, 6)
                    .opacity(entry.isCompleted ? 0.75 : 1.0)
                }
            }

            Button("Finish Session") {
                if saveContext() {
                    dismiss()
                }
            }
            .disabled(!canFinish)
        }
        .navigationTitle(template?.name ?? "Session")
        .alert("Could Not Save", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    @ViewBuilder
    private func field(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
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

    private func lastTimeEntry(for entry: SessionExercise) -> SessionExercise? {
        SessionHistoryLookup.lastCompletedEntry(
            for: entry.movementId,
            equipment: entry.equipment,
            in: allSessions,
            excludingSessionId: session.id
        )
    }

    private func useLastTime(for entry: SessionExercise) {
        guard let previous = lastTimeEntry(for: entry) else { return }

        entry.sets = previous.sets
        entry.reps = previous.reps
        entry.weight = previous.weight
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            saveErrorMessage = error.localizedDescription
            return false
        }
    }
}
