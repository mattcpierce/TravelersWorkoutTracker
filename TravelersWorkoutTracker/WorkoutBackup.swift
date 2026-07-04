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

    enum RestoreMode {
        case merge
        case replace
    }

    enum BackupError: LocalizedError {
        case unsupportedSchemaVersion(Int)

        var errorDescription: String? {
            switch self {
            case .unsupportedSchemaVersion(let version):
                return "This backup was created by a newer version of the app (format \(version)). Update the app to restore it."
            }
        }
    }

    static func restore(_ backup: WorkoutBackup, into context: ModelContext, mode: RestoreMode) throws {
        guard backup.schemaVersion <= currentSchemaVersion else {
            throw BackupError.unsupportedSchemaVersion(backup.schemaVersion)
        }

        if mode == .replace {
            try deleteAll(WorkoutSession.self, in: context)
            try deleteAll(SessionExercise.self, in: context)
            try deleteAll(WorkoutTemplate.self, in: context)
            try deleteAll(ActiveSession.self, in: context)
            try deleteAll(PlannedSession.self, in: context)
            try deleteAll(Movement.self, in: context)
        }

        let existingMovements = try lookup(Movement.self, by: \.id, in: context)
        for entry in backup.movements {
            if let movement = existingMovements[entry.id] {
                movement.name = entry.name
                movement.description = entry.movementDescription
                movement.category = entry.category
                movement.tags = entry.tags
                movement.hotelAlternativeMovementId = entry.hotelAlternativeMovementId
                movement.allowedModalities = entry.allowedModalities
                movement.isCustom = entry.isCustom
            } else {
                context.insert(Movement(
                    id: entry.id,
                    name: entry.name,
                    description: entry.movementDescription,
                    category: entry.category,
                    tags: entry.tags,
                    hotelAlternativeMovementId: entry.hotelAlternativeMovementId,
                    allowedModalities: entry.allowedModalities,
                    isCustom: entry.isCustom
                ))
            }
        }

        let existingPlans = try lookup(PlannedSession.self, by: \.id, in: context)
        for entry in backup.plannedSessions {
            if let plan = existingPlans[entry.id] {
                plan.name = entry.name
                plan.blocks = entry.blocks
                plan.lastPerformedDate = entry.lastPerformedDate
            } else {
                context.insert(PlannedSession(
                    id: entry.id,
                    name: entry.name,
                    blocks: entry.blocks,
                    lastPerformedDate: entry.lastPerformedDate
                ))
            }
        }

        let existingActiveSessions = try lookup(ActiveSession.self, by: \.id, in: context)
        for entry in backup.activeSessions {
            if let session = existingActiveSessions[entry.id] {
                session.plannedSessionId = entry.plannedSessionId
                session.startTime = entry.startTime
                session.completedAt = entry.completedAt
                session.isTravelMode = entry.isTravelMode
                session.status = entry.status
                session.blocks = entry.blocks
            } else {
                context.insert(ActiveSession(
                    id: entry.id,
                    plannedSessionId: entry.plannedSessionId,
                    startTime: entry.startTime,
                    completedAt: entry.completedAt,
                    isTravelMode: entry.isTravelMode,
                    status: entry.status,
                    blocks: entry.blocks
                ))
            }
        }

        let existingTemplates = try lookup(WorkoutTemplate.self, by: \.id, in: context)
        for entry in backup.workoutTemplates {
            if let template = existingTemplates[entry.id] {
                template.name = entry.name
                template.orderedMovements = entry.orderedMovements
            } else {
                context.insert(WorkoutTemplate(
                    id: entry.id,
                    name: entry.name,
                    orderedMovements: entry.orderedMovements
                ))
            }
        }

        // Workout sessions own their exercises via a cascade relationship, so
        // an updated entry is replaced wholesale rather than patched in place.
        let existingWorkouts = try lookup(WorkoutSession.self, by: \.id, in: context)
        for entry in backup.workoutSessions {
            if let workout = existingWorkouts[entry.id] {
                context.delete(workout)
            }
            context.insert(WorkoutSession(
                id: entry.id,
                date: entry.date,
                templateId: entry.templateId,
                sessionExercises: entry.exercises.map { exercise in
                    SessionExercise(
                        id: exercise.id,
                        movementId: exercise.movementId,
                        equipment: exercise.equipment,
                        sets: exercise.sets,
                        reps: exercise.reps,
                        weight: exercise.weight,
                        rpe: exercise.rpe,
                        notes: exercise.notes,
                        isCompleted: exercise.isCompleted
                    )
                }
            ))
        }

        try context.save()
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) throws {
        for object in try context.fetch(FetchDescriptor<T>()) {
            context.delete(object)
        }
    }

    private static func lookup<T: PersistentModel>(
        _ type: T.Type,
        by id: KeyPath<T, String>,
        in context: ModelContext
    ) throws -> [String: T] {
        Dictionary(
            try context.fetch(FetchDescriptor<T>()).map { ($0[keyPath: id], $0) },
            uniquingKeysWith: { first, _ in first }
        )
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
