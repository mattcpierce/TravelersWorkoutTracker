// EquipmentPickerView.swift
import SwiftUI

struct EquipmentPickerView: View {
    let title: String
    let options: [EquipmentType]
    @Binding var selection: EquipmentType

    var body: some View {
        if options.count <= 5 {
            Picker(title, selection: $selection) {
                ForEach(options) { equipment in
                    Text(equipment.label).tag(equipment)
                }
            }
            .pickerStyle(.segmented)
        } else {
            Picker(title, selection: $selection) {
                ForEach(options) { equipment in
                    Text(equipment.label).tag(equipment)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        EquipmentPickerView(
            title: "Equipment",
            options: [.barbell, .dumbbells, .machine],
            selection: .constant(.dumbbells)
        )

        EquipmentPickerView(
            title: "Equipment",
            options: EquipmentType.allCases,
            selection: .constant(.treadmill)
        )
    }
    .padding()
}
