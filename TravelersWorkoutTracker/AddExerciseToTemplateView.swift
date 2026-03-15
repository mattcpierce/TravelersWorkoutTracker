// AddExerciseToTemplateView.swift
import SwiftData
import SwiftUI

struct AddExerciseToTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Movement.name)]) private var allMovements: [Movement]

    @State private var searchText = ""
    @State private var pendingMovement: Movement?
    @State private var showingModalityDialog = false

    let onAdd: (Movement, EquipmentType) -> Void

    private var filteredMovements: [Movement] {
        if searchText.isEmpty { return allMovements }
        return allMovements.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Choose Movement") {
                    ForEach(filteredMovements) { movement in
                        Button {
                            pendingMovement = movement
                            showingModalityDialog = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(movement.name)
                                    .foregroundStyle(.primary)
                                Text(movement.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add Movement")
            .searchable(text: $searchText, prompt: "Search movements")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Choose Modality",
                isPresented: $showingModalityDialog,
                titleVisibility: .visible
            ) {
                ForEach(allowedModalitiesForPendingMovement) { equipment in
                    Button(modalityLabel(for: equipment)) {
                        guard let pendingMovement else { return }
                        onAdd(pendingMovement, equipment)
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {
                    pendingMovement = nil
                }
            } message: {
                Text(pendingMovement?.name ?? "Select a modality")
            }
        }
    }

    private func modalityLabel(for equipment: EquipmentType) -> String {
        switch equipment {
        case .dumbbells:
            return "Dumbbell"
        case .barbell:
            return "Barbell"
        case .landmine:
            return "Landmine"
        case .bodyweight:
            return "Bodyweight"
        case .kettlebell:
            return "Kettlebell"
        case .resistanceBand:
            return "Bands"
        default:
            return equipment.label
        }
    }

    private var allowedModalitiesForPendingMovement: [EquipmentType] {
        guard let pendingMovement else { return MovementCatalog.defaultAllowedModalities }
        return pendingMovement.allowedModalities.isEmpty ? MovementCatalog.defaultAllowedModalities : pendingMovement.allowedModalities
    }
}

#Preview {
    AddExerciseToTemplateView { _, _ in }
        .modelContainer(for: [Movement.self], inMemory: true)
}
