import Foundation

struct ActiveSessionHistoryEntry: Identifiable, Hashable {
    let id: String
    let blockId: String
    let blockOrder: Int
    let blockType: SessionBlockType
    let roundNumber: Int
    let movementId: String
    let modality: EquipmentType
    let plannedSets: Int
    let plannedReps: Int
    let actualWeight: Int?
    let actualReps: Int?
    let rpe: Int?
    let status: ExerciseExecutionStatus
    let notes: String?
}

struct ActiveSessionHistorySupport {
    static func completedDate(for session: ActiveSession) -> Date {
        session.completedAt ?? session.startTime
    }

    static func isCompletedSession(_ session: ActiveSession) -> Bool {
        session.status == .completed
    }

    static func flattenedEntries(for session: ActiveSession) -> [ActiveSessionHistoryEntry] {
        session.blocks
            .sorted { $0.order < $1.order }
            .flatMap { block in
                block.items.flatMap { item in
                    item.roundLogs
                        .sorted { $0.roundNumber < $1.roundNumber }
                        .map { log in
                            ActiveSessionHistoryEntry(
                                id: "\(session.id)-\(block.id)-\(item.id)-\(log.roundNumber)",
                                blockId: block.id,
                                blockOrder: block.order,
                                blockType: block.type,
                                roundNumber: log.roundNumber,
                                movementId: item.effectiveMovementId,
                                modality: item.selectedModality,
                                plannedSets: item.plannedSets,
                                plannedReps: item.plannedReps,
                                actualWeight: log.actualWeight,
                                actualReps: log.actualReps,
                                rpe: log.rpe,
                                status: log.status,
                                notes: log.notes
                            )
                        }
                }
            }
    }

    static func sessionMatchesSearch(_ session: ActiveSession, plannedSessionName: String, query: String) -> Bool {
        query.isEmpty || plannedSessionName.localizedCaseInsensitiveContains(query)
    }

    static func lastCompletedEntry(
        for movementId: String,
        in sessions: [ActiveSession],
        excludingSessionId: String? = nil
    ) -> (session: ActiveSession, entry: ActiveSessionHistoryEntry)? {
        let sortedSessions = sessions
            .filter { $0.status == .completed }
            .sorted { completedDate(for: $0) > completedDate(for: $1) }

        for session in sortedSessions {
            if let excludingSessionId, session.id == excludingSessionId {
                continue
            }

            if let match = flattenedEntries(for: session).first(where: {
                $0.movementId == movementId && $0.status == .completed && $0.rpe != nil
            }) {
                return (session, match)
            }
        }

        return nil
    }

    static func lastCompletedEntry(
        for movementId: String,
        modality: EquipmentType,
        in sessions: [ActiveSession],
        excludingSessionId: String? = nil
    ) -> (session: ActiveSession, entry: ActiveSessionHistoryEntry)? {
        let sortedSessions = sessions
            .filter { $0.status == .completed }
            .sorted { completedDate(for: $0) > completedDate(for: $1) }

        for session in sortedSessions {
            if let excludingSessionId, session.id == excludingSessionId {
                continue
            }

            if let match = flattenedEntries(for: session).first(where: {
                $0.movementId == movementId &&
                $0.modality == modality &&
                $0.status == .completed
            }) {
                return (session, match)
            }
        }

        return nil
    }

    static func summaryText(for entry: ActiveSessionHistoryEntry) -> String {
        let reps = entry.actualReps ?? entry.plannedReps
        let weight = entry.actualWeight ?? 0
        let rpeText = entry.rpe.map { " @ RPE \($0)" } ?? ""
        return "\(entry.plannedSets)x\(reps) @ \(weight)\(rpeText)"
    }
}
