import Foundation
import SwiftData

enum ActiveSessionFactory {
    static let defaultPlannedSets = 3
    static let defaultPlannedReps = 10

    static func makeSingleExerciseBlock(
        movement: Movement,
        modality: EquipmentType,
        order: Int
    ) -> ActiveSessionBlock {
        let item = ActiveSessionItem(
            movementId: movement.id,
            effectiveMovementId: movement.id,
            selectedModality: modality,
            plannedSets: defaultPlannedSets,
            plannedReps: defaultPlannedReps,
            actualWeight: modality == .bodyweight ? 0 : nil,
            actualReps: nil,
            rpe: nil,
            status: .notStarted,
            notes: nil
        )
        return ActiveSessionBlock(
            type: .single,
            order: order,
            currentRound: 1,
            roundsCompleted: 0,
            items: [item]
        )
    }

    @MainActor
    static func createActiveSession(
        context: ModelContext,
        from plannedSession: PlannedSession,
        isTravelMode: Bool
    ) throws -> ActiveSession {
        let movements = try context.fetch(FetchDescriptor<Movement>())
        let movementLookup = Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })

        let blocks = plannedSession.blocks
            .sorted { $0.order < $1.order }
            .map { block in
                let items = block.items
                    .sorted { $0.blockPosition < $1.blockPosition }
                    .map { item in
                        let originalMovementId = item.movementId
                        let hotelAlternativeId = movementLookup[originalMovementId]?.hotelAlternativeMovementId
                        let effectiveMovementId = (isTravelMode ? hotelAlternativeId : nil) ?? originalMovementId
                        let allowedModalities = movementLookup[effectiveMovementId]?.allowedModalities ?? []

                        return ActiveSessionItem(
                            movementId: originalMovementId,
                            effectiveMovementId: effectiveMovementId,
                            selectedModality: allowedModalities.first ?? .bodyweight,
                            plannedSets: item.plannedSets,
                            plannedReps: item.plannedReps,
                            status: .notStarted,
                            notes: item.notes
                        )
                    }

                return ActiveSessionBlock(
                    type: block.type,
                    order: block.order,
                    currentRound: 1,
                    roundsCompleted: 0,
                    items: items
                )
            }

        let activeSession = ActiveSession(
            plannedSessionId: plannedSession.id,
            startTime: .now,
            isTravelMode: isTravelMode,
            status: .active,
            blocks: blocks
        )

        context.insert(activeSession)
        try context.save()
        return activeSession
    }
}
