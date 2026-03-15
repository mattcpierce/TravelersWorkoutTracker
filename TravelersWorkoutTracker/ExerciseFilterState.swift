// ExerciseFilterState.swift
import Foundation

struct ExerciseFilterState: Equatable {
    var selectedEquipment: Set<EquipmentType> = []
    var hotelOnly = false

    var activeFilterCount: Int {
        selectedEquipment.count + (hotelOnly ? 1 : 0)
    }

    static func decodeEquipment(from persistedValue: String) -> Set<EquipmentType> {
        let values = persistedValue
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(values.compactMap(EquipmentType.init(rawValue:)))
    }

    static func encodeEquipment(_ selectedEquipment: Set<EquipmentType>) -> String {
        selectedEquipment.map(\.rawValue).sorted().joined(separator: ",")
    }
}
