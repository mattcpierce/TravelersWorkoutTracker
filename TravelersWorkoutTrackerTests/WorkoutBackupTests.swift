import Foundation
import SwiftData
import Testing
@testable import TravelersWorkoutTracker

@MainActor
@Suite(.serialized)
struct WorkoutBackupTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Movement.self, PlannedSession.self, ActiveSession.self,
            WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func populate(_ context: ModelContext) throws {
        context.insert(Movement(
            id: "custom-band-pull",
            name: "Band Pull-Apart",
            description: "test",
            category: "Horizontal Pull",
            tags: ["upper-back"],
            allowedModalities: [.resistanceBand],
            isCustom: true
        ))
        context.insert(PlannedSession(
            id: "plan-1",
            name: "Push Day",
            blocks: [SessionBlock(type: .single, order: 0, items: [
                SessionBlockItem(movementId: "custom-band-pull", plannedSets: 3, plannedReps: 12, notes: "warm up", blockPosition: 0)
            ])],
            lastPerformedDate: Date(timeIntervalSince1970: 1_750_000_000)
        ))
        context.insert(ActiveSession(
            id: "active-1",
            plannedSessionId: "plan-1",
            isTravelMode: true,
            status: .active,
            blocks: [ActiveSessionBlock(type: .single, order: 0, currentRound: 1, roundsCompleted: 0, items: [
                ActiveSessionItem(
                    movementId: "custom-band-pull",
                    effectiveMovementId: "custom-band-pull",
                    selectedModality: .resistanceBand,
                    plannedSets: 3,
                    plannedReps: 12,
                    actualWeight: nil,
                    actualReps: nil,
                    rpe: nil,
                    status: .notStarted,
                    notes: nil
                )
            ])]
        ))
        context.insert(WorkoutTemplate(
            id: "template-1",
            name: "Legacy Template",
            orderedMovements: [TemplateMovement(movementId: "custom-band-pull", defaultEquipment: .resistanceBand)]
        ))
        context.insert(WorkoutSession(
            id: "workout-1",
            date: Date(timeIntervalSince1970: 1_740_000_000),
            templateId: "template-1",
            sessionExercises: [SessionExercise(movementId: "custom-band-pull", equipment: .resistanceBand, sets: 3, reps: 12, weight: 0, rpe: 7)]
        ))
        try context.save()
    }

    @Test func exportedJSONRoundTrips() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try populate(context)

        let data = try WorkoutBackupService.exportJSON(context: context)
        let backup = try WorkoutBackupService.decodeBackup(from: data)

        #expect(backup.schemaVersion == WorkoutBackupService.currentSchemaVersion)
        #expect(backup.movements.count == 1)
        #expect(backup.plannedSessions.count == 1)
        #expect(backup.activeSessions.count == 1)
        #expect(backup.workoutTemplates.count == 1)
        #expect(backup.workoutSessions.count == 1)

        let movement = try #require(backup.movements.first)
        #expect(movement.id == "custom-band-pull")
        #expect(movement.isCustom)
        #expect(movement.allowedModalities == [.resistanceBand])

        let plan = try #require(backup.plannedSessions.first)
        #expect(plan.blocks.first?.items.first?.notes == "warm up")
        #expect(plan.lastPerformedDate == Date(timeIntervalSince1970: 1_750_000_000))

        let active = try #require(backup.activeSessions.first)
        #expect(active.isTravelMode)
        #expect(active.blocks.first?.items.first?.selectedModality == .resistanceBand)

        let workout = try #require(backup.workoutSessions.first)
        #expect(workout.exercises.count == 1)
        #expect(workout.exercises.first?.reps == 12)
    }

    @Test func exportOfEmptyStoreProducesEmptyCollections() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let backup = try WorkoutBackupService.decodeBackup(from: WorkoutBackupService.exportJSON(context: context))

        #expect(backup.movements.isEmpty)
        #expect(backup.plannedSessions.isEmpty)
        #expect(backup.activeSessions.isEmpty)
        #expect(backup.workoutTemplates.isEmpty)
        #expect(backup.workoutSessions.isEmpty)
    }

    @Test func restoreReplaceMatchesBackupExactly() throws {
        let sourceContainer = try makeContainer()
        try populate(sourceContainer.mainContext)
        let backup = try WorkoutBackupService.makeBackup(context: sourceContainer.mainContext)

        let targetContainer = try makeContainer()
        let target = targetContainer.mainContext
        target.insert(Movement(id: "doomed", name: "Doomed", description: "will be deleted", isCustom: true))
        target.insert(PlannedSession(id: "doomed-plan", name: "Doomed Plan"))
        try target.save()

        try WorkoutBackupService.restore(backup, into: target, mode: .replace)

        let movements = try target.fetch(FetchDescriptor<Movement>())
        #expect(movements.map(\.id) == ["custom-band-pull"])
        let plans = try target.fetch(FetchDescriptor<PlannedSession>())
        #expect(plans.map(\.id) == ["plan-1"])
        #expect(try target.fetch(FetchDescriptor<WorkoutSession>()).count == 1)
        #expect(try target.fetch(FetchDescriptor<SessionExercise>()).count == 1)
    }

    @Test func restoreMergeUpsertsAndPreservesExtras() throws {
        let sourceContainer = try makeContainer()
        try populate(sourceContainer.mainContext)
        let backup = try WorkoutBackupService.makeBackup(context: sourceContainer.mainContext)

        let targetContainer = try makeContainer()
        let target = targetContainer.mainContext
        target.insert(Movement(id: "custom-band-pull", name: "Stale Name", description: "stale", isCustom: true))
        target.insert(Movement(id: "keep-me", name: "Keeper", description: "not in backup", isCustom: true))
        try target.save()

        try WorkoutBackupService.restore(backup, into: target, mode: .merge)

        let movements = try target.fetch(FetchDescriptor<Movement>())
        #expect(movements.count == 2)
        let updated = try #require(movements.first { $0.id == "custom-band-pull" })
        #expect(updated.name == "Band Pull-Apart")
        #expect(movements.contains { $0.id == "keep-me" })
        #expect(try target.fetch(FetchDescriptor<PlannedSession>()).count == 1)
    }

    @Test func restoreMergeReplacesWorkoutSessionExercisesWithoutOrphans() throws {
        let sourceContainer = try makeContainer()
        try populate(sourceContainer.mainContext)
        let backup = try WorkoutBackupService.makeBackup(context: sourceContainer.mainContext)

        let targetContainer = try makeContainer()
        let target = targetContainer.mainContext
        target.insert(WorkoutSession(
            id: "workout-1",
            templateId: "template-1",
            sessionExercises: [
                SessionExercise(movementId: "old-a", equipment: .barbell),
                SessionExercise(movementId: "old-b", equipment: .barbell)
            ]
        ))
        try target.save()

        try WorkoutBackupService.restore(backup, into: target, mode: .merge)

        let workouts = try target.fetch(FetchDescriptor<WorkoutSession>())
        #expect(workouts.count == 1)
        #expect(workouts.first?.sessionExercises?.count == 1)
        #expect(try target.fetch(FetchDescriptor<SessionExercise>()).count == 1)
    }

    @Test func restoreRejectsNewerSchemaVersion() throws {
        let container = try makeContainer()
        let backup = WorkoutBackup(
            schemaVersion: WorkoutBackupService.currentSchemaVersion + 1,
            exportedAt: .now,
            movements: [],
            plannedSessions: [],
            activeSessions: [],
            workoutTemplates: [],
            workoutSessions: []
        )

        #expect(throws: WorkoutBackupService.BackupError.self) {
            try WorkoutBackupService.restore(backup, into: container.mainContext, mode: .merge)
        }
    }

    @Test func defaultFilenameIncludesDate() {
        let date = Date(timeIntervalSince1970: 1_751_600_000) // 2025-07-04 UTC
        let name = WorkoutBackupService.defaultFilename(for: date)
        #expect(name.hasPrefix("TravelersWorkout-Backup-"))
        #expect(name.contains("2025"))
    }
}
