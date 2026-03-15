// TemplateDetailView.swift
import SwiftData
import SwiftUI

struct TemplateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Movement.name)]) private var allMovements: [Movement]

    @Bindable var template: WorkoutTemplate
    let shouldShowAddMovementOnAppear: Bool
    @State private var showingMovementPicker = false
    @State private var hasPresentedInitialAdd = false

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: allMovements.map { ($0.id, $0) })
    }

    var body: some View {
        List {
            Section("Template") {
                TextField("Template Name", text: $template.name)
                    .textInputAutocapitalization(.words)
                    .onSubmit(saveChanges)
            }

            Section("Movements") {
                if template.orderedMovements.isEmpty {
                    Text("No movements added yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(template.orderedMovements.enumerated()), id: \.offset) { index, entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(movementLookup[entry.movementId]?.name ?? "Unknown Movement")
                                Text(entry.defaultEquipment.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("#\(index + 1)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: removeEntries)
                    .onMove(perform: moveEntries)
                }
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Movement") {
                    showingMovementPicker = true
                }
            }
        }
        .sheet(isPresented: $showingMovementPicker) {
            AddExerciseToTemplateView { movement, equipment in
                template.orderedMovements.append(TemplateMovement(movementId: movement.id, defaultEquipment: equipment))
                saveChanges()
            }
        }
        .onAppear {
            guard shouldShowAddMovementOnAppear, !hasPresentedInitialAdd else { return }
            hasPresentedInitialAdd = true
            showingMovementPicker = true
        }
        .onDisappear(perform: saveChanges)
    }

    init(template: WorkoutTemplate, shouldShowAddMovementOnAppear: Bool = false) {
        self._template = Bindable(template)
        self.shouldShowAddMovementOnAppear = shouldShowAddMovementOnAppear
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        template.orderedMovements.move(fromOffsets: source, toOffset: destination)
        saveChanges()
    }

    private func removeEntries(at offsets: IndexSet) {
        template.orderedMovements.remove(atOffsets: offsets)
        saveChanges()
    }

    private func saveChanges() {
        if template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            template.name = "Untitled Template"
        }
        try? modelContext.save()
    }
}
