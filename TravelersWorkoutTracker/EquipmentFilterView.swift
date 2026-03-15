// EquipmentFilterView.swift
import SwiftUI

struct EquipmentFilterView: View {
    let equipmentOptions: [EquipmentType]
    @Binding var selectedEquipment: Set<EquipmentType>

    var body: some View {
        if equipmentOptions.isEmpty {
            Text("No equipment options available")
                .foregroundStyle(.secondary)
        } else {
            ForEach(equipmentOptions) { equipment in
                Button {
                    toggleSelection(for: equipment)
                } label: {
                    HStack {
                        Text(equipment.label)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedEquipment.contains(equipment) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
        }
    }

    private func toggleSelection(for equipment: EquipmentType) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }
}

#Preview {
    EquipmentFilterView(
        equipmentOptions: EquipmentType.allCases,
        selectedEquipment: .constant([.dumbbells, .treadmill])
    )
}
