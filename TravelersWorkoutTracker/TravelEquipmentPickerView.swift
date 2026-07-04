import SwiftUI

struct TravelEquipmentPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<EquipmentType>

    let onStart: ([EquipmentType]) -> Void

    private static let storageKey = "travelEquipmentSelection"
    private static let defaultSelection: Set<EquipmentType> = [.bodyweight, .dumbbells, .machine, .cable, .treadmill]

    init(onStart: @escaping ([EquipmentType]) -> Void) {
        self.onStart = onStart
        if let stored = UserDefaults.standard.stringArray(forKey: Self.storageKey) {
            _selected = State(initialValue: Set(stored.compactMap(EquipmentType.init(rawValue:))))
        } else {
            _selected = State(initialValue: Self.defaultSelection)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(EquipmentType.allCases) { equipment in
                        Button {
                            toggle(equipment)
                        } label: {
                            HStack {
                                Text(equipment.label)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected.contains(equipment) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("What does this gym have?")
                } footer: {
                    Text("Exercises will default to equipment on this list when possible. Your selection is remembered for the next trip.")
                }
            }
            .navigationTitle("Hotel Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        let equipment = EquipmentType.allCases.filter(selected.contains)
                        UserDefaults.standard.set(equipment.map(\.rawValue), forKey: Self.storageKey)
                        dismiss()
                        onStart(equipment)
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
    }

    private func toggle(_ equipment: EquipmentType) {
        if selected.contains(equipment) {
            selected.remove(equipment)
        } else {
            selected.insert(equipment)
        }
    }
}

#Preview {
    TravelEquipmentPickerView { _ in }
}
