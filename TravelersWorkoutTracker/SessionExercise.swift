// SessionExercise.swift
import Foundation
import SwiftData

@Model
final class SessionExercise {
    @Attribute(.unique) var id: String
    var movementId: String
    var equipment: EquipmentType
    var sets: Int
    var reps: Int
    var weight: Int
    var rpe: Int
    var notes: String?
    var isCompleted: Bool

    init(
        id: String = UUID().uuidString,
        movementId: String,
        equipment: EquipmentType,
        sets: Int = 0,
        reps: Int = 0,
        weight: Int = 0,
        rpe: Int = 0,
        notes: String? = nil,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.movementId = movementId
        self.equipment = equipment
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.notes = notes
        self.isCompleted = isCompleted
    }
}
