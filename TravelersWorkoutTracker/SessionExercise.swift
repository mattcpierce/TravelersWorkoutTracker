// SessionExercise.swift
import Foundation
import SwiftData

@Model
final class SessionExercise {
    var id: String = UUID().uuidString
    var movementId: String = ""
    var equipment: EquipmentType = EquipmentType.bodyweight
    var sets: Int = 0
    var reps: Int = 0
    var weight: Int = 0
    var rpe: Int = 0
    var notes: String?
    var isCompleted: Bool = false
    var workoutSession: WorkoutSession?

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
