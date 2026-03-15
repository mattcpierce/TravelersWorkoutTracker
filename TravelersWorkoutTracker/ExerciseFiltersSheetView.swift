// ExerciseFiltersSheetView.swift
import SwiftUI

struct ExerciseFiltersSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filterState: ExerciseFilterState
    let equipmentOptions: [EquipmentType]

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Toggle("Hotel Friendly Only", isOn: $filterState.hotelOnly)
                }

                Section("Equipment") {
                    EquipmentFilterView(
                        equipmentOptions: equipmentOptions,
                        selectedEquipment: $filterState.selectedEquipment
                    )
                }
            }
            .navigationTitle("Exercise Filters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Clear All") {
                        filterState = ExerciseFilterState()
                    }
                    .disabled(filterState.activeFilterCount == 0)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ExerciseFiltersSheetView(
        filterState: .constant(ExerciseFilterState(selectedEquipment: [.dumbbells], hotelOnly: true)),
        equipmentOptions: EquipmentType.allCases
    )
}
