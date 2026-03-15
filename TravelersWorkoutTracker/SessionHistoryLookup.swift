// SessionHistoryLookup.swift
import Foundation

struct SessionHistoryLookup {
    static func lastCompletedEntry(
        for movementId: String,
        equipment: EquipmentType,
        in sessions: [WorkoutSession],
        excludingSessionId: String? = nil
    ) -> SessionExercise? {
        for session in sessions {
            if let excludingSessionId, session.id == excludingSessionId {
                continue
            }

            if let match = session.sessionExercises.first(where: {
                $0.movementId == movementId && $0.equipment == equipment && $0.rpe >= 6 && $0.rpe <= 10
            }) {
                return match
            }
        }

        return nil
    }

    static func summaryText(for entry: SessionExercise) -> String {
        "\(entry.sets)x\(entry.reps) @ \(entry.weight) @ RPE \(entry.rpe)"
    }
}
