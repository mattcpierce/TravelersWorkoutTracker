import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct WorkoutBackup: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var movements: [MovementBackup]
    var plannedSessions: [PlannedSessionBackup]
    var activeSessions: [ActiveSessionBackup]
    var workoutTemplates: [WorkoutTemplateBackup]
    var workoutSessions: [WorkoutSessionBackup]
}

struct MovementBackup: Codable {
    var id: String
    var name: String
    var movementDescription: String
    var category: String
    var tags: [String]
    var hotelAlternativeMovementId: String?
    var allowedModalities: [EquipmentType]
    var isCustom: Bool

    init(_ movement: Movement) {
        id = movement.id
        name = movement.name
        movementDescription = movement.description
        category = movement.category
        tags = movement.tags
        hotelAlternativeMovementId = movement.hotelAlternativeMovementId
        allowedModalities = movement.allowedModalities
        isCustom = movement.isCustom
    }
}

struct PlannedSessionBackup: Codable {
    var id: String
    var name: String
    var blocks: [SessionBlock]
    var lastPerformedDate: Date?

    init(_ session: PlannedSession) {
        id = session.id
        name = session.name
        blocks = session.blocks
        lastPerformedDate = session.lastPerformedDate
    }
}

struct ActiveSessionBackup: Codable {
    var id: String
    var plannedSessionId: String
    var startTime: Date
    var completedAt: Date?
    var isTravelMode: Bool
    var status: ActiveSessionStatus
    var blocks: [ActiveSessionBlock]

    init(_ session: ActiveSession) {
        id = session.id
        plannedSessionId = session.plannedSessionId
        startTime = session.startTime
        completedAt = session.completedAt
        isTravelMode = session.isTravelMode
        status = session.status
        blocks = session.blocks
    }
}

struct WorkoutTemplateBackup: Codable {
    var id: String
    var name: String
    var orderedMovements: [TemplateMovement]

    init(_ template: WorkoutTemplate) {
        id = template.id
        name = template.name
        orderedMovements = template.orderedMovements
    }
}

struct WorkoutSessionBackup: Codable {
    var id: String
    var date: Date
    var templateId: String
    var exercises: [SessionExerciseBackup]

    init(_ session: WorkoutSession) {
        id = session.id
        date = session.date
        templateId = session.templateId
        exercises = session.sessionExercises.map(SessionExerciseBackup.init)
    }
}

struct SessionExerciseBackup: Codable {
    var id: String
    var movementId: String
    var equipment: EquipmentType
    var sets: Int
    var reps: Int
    var weight: Int
    var rpe: Int
    var notes: String?
    var isCompleted: Bool

    init(_ exercise: SessionExercise) {
        id = exercise.id
        movementId = exercise.movementId
        equipment = exercise.equipment
        sets = exercise.sets
        reps = exercise.reps
        weight = exercise.weight
        rpe = exercise.rpe
        notes = exercise.notes
        isCompleted = exercise.isCompleted
    }
}

@MainActor
enum WorkoutBackupService {
    static let currentSchemaVersion = 1

    static func makeBackup(context: ModelContext) throws -> WorkoutBackup {
        WorkoutBackup(
            schemaVersion: currentSchemaVersion,
            exportedAt: .now,
            movements: try context.fetch(FetchDescriptor<Movement>()).map(MovementBackup.init),
            plannedSessions: try context.fetch(FetchDescriptor<PlannedSession>()).map(PlannedSessionBackup.init),
            activeSessions: try context.fetch(FetchDescriptor<ActiveSession>()).map(ActiveSessionBackup.init),
            workoutTemplates: try context.fetch(FetchDescriptor<WorkoutTemplate>()).map(WorkoutTemplateBackup.init),
            workoutSessions: try context.fetch(FetchDescriptor<WorkoutSession>()).map(WorkoutSessionBackup.init)
        )
    }

    static func exportJSON(context: ModelContext) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(makeBackup(context: context))
    }

    static func decodeBackup(from data: Data) throws -> WorkoutBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutBackup.self, from: data)
    }

    static func defaultFilename(for date: Date = .now) -> String {
        let stamp = date.formatted(.iso8601.year().month().day())
        return "TravelersWorkout-Backup-\(stamp)"
    }
}

struct WorkoutBackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
