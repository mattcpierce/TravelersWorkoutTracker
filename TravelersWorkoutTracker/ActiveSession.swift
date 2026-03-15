import Foundation
import SwiftData

enum ExerciseExecutionStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case completed
    case skipped
    case incomplete

    var id: String { rawValue }
}

enum ActiveSessionStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case completed
    case abandoned

    var id: String { rawValue }
}

struct ActiveSessionItem: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var movementId: String
    var effectiveMovementId: String
    var selectedModality: EquipmentType
    var plannedSets: Int
    var plannedReps: Int
    var actualWeight: Int?
    var actualReps: Int?
    var rpe: Int?
    var status: ExerciseExecutionStatus
    var notes: String?
    var roundLogs: [ActiveSessionRoundLog] = []

    func log(for round: Int) -> ActiveSessionRoundLog? {
        roundLogs.first { $0.roundNumber == round }
    }

    mutating func upsertLog(_ log: ActiveSessionRoundLog) {
        if let index = roundLogs.firstIndex(where: { $0.roundNumber == log.roundNumber }) {
            roundLogs[index] = log
        } else {
            roundLogs.append(log)
            roundLogs.sort { $0.roundNumber < $1.roundNumber }
        }
        if let latestLog = roundLogs.max(by: { $0.roundNumber < $1.roundNumber }) {
            actualWeight = latestLog.actualWeight
            actualReps = latestLog.actualReps
            rpe = latestLog.rpe
            status = latestLog.status
            notes = latestLog.notes
        }
    }
}

struct ActiveSessionRoundLog: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var roundNumber: Int
    var actualWeight: Int?
    var actualReps: Int?
    var rpe: Int?
    var status: ExerciseExecutionStatus
    var notes: String?
}

struct ActiveSessionBlock: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var type: SessionBlockType
    var order: Int
    var currentRound: Int
    var roundsCompleted: Int
    var items: [ActiveSessionItem]

    var totalRounds: Int {
        max(items.map(\.plannedSets).max() ?? 0, 0)
    }

    var isFinished: Bool {
        totalRounds > 0 && roundsCompleted >= totalRounds
    }

    func itemsForCurrentRound() -> [ActiveSessionItem] {
        items.filter { currentRound <= $0.plannedSets }
    }
}

@Model
final class ActiveSession {
    @Attribute(.unique) var id: String
    var plannedSessionId: String
    var startTime: Date
    var completedAt: Date?
    var isTravelMode: Bool
    var status: ActiveSessionStatus
    @Attribute(.externalStorage) var blocks: [ActiveSessionBlock]

    init(
        id: String = UUID().uuidString,
        plannedSessionId: String,
        startTime: Date = .now,
        completedAt: Date? = nil,
        isTravelMode: Bool = false,
        status: ActiveSessionStatus = .active,
        blocks: [ActiveSessionBlock] = []
    ) {
        self.id = id
        self.plannedSessionId = plannedSessionId
        self.startTime = startTime
        self.completedAt = completedAt
        self.isTravelMode = isTravelMode
        self.status = status
        self.blocks = blocks
    }
}
