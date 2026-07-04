import Foundation
import SwiftData
import Testing
@testable import TravelersWorkoutTracker

@MainActor
@Suite(.serialized)
struct MovementSeederTests {
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Movement.self, ActiveSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MovementSeederTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    // MARK: - Seed data integrity

    @Test func seedDataHasUniqueIds() {
        let ids = MovementSeeder.builtInMovements.map(\.id)
        #expect(ids.count == Set(ids).count)
    }

    @Test func seedDataReferencesOnlyExistingHotelAlternatives() {
        let ids = Set(MovementSeeder.builtInMovements.map(\.id))
        for seed in MovementSeeder.builtInMovements {
            if let alternativeId = seed.hotelAlternativeMovementId {
                #expect(ids.contains(alternativeId), "\(seed.id) points at missing \(alternativeId)")
            }
        }
    }

    // MARK: - Seeding

    @Test func freshSeedInsertsBuiltInMovements() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let movements = try context.fetch(FetchDescriptor<Movement>())
        #expect(!movements.isEmpty)
        #expect(movements.allSatisfy { !$0.isCustom })
        #expect(movements.contains { $0.id == "back-squat" })
        #expect(defaults.integer(forKey: "movementSeedVersion") == MovementSeeder.seedVersion)
    }

    @Test func versionBumpUpdatesExistingBuiltIns() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        context.insert(Movement(id: "back-squat", name: "Old Name", description: "old"))
        try context.save()
        defaults.set(MovementSeeder.seedVersion - 1, forKey: "movementSeedVersion")

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let movements = try context.fetch(FetchDescriptor<Movement>())
        let backSquat = try #require(movements.first { $0.id == "back-squat" })
        #expect(backSquat.name == "Back Squat")
        #expect(!backSquat.isCustom)
    }

    @Test func customMovementsAreNotOverwritten() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        context.insert(Movement(id: "back-squat", name: "My Squat", description: "mine", isCustom: true))
        context.insert(Movement(id: "custom-thing", name: "My Thing", description: "mine", isCustom: true))
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let movements = try context.fetch(FetchDescriptor<Movement>())
        let collided = try #require(movements.first { $0.id == "back-squat" })
        #expect(collided.name == "My Squat")
        #expect(collided.isCustom)
        #expect(movements.contains { $0.id == "custom-thing" })
    }

    @Test func currentVersionWithBuiltInsSkipsReseed() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let movements = try context.fetch(FetchDescriptor<Movement>())
        let backSquat = try #require(movements.first { $0.id == "back-squat" })
        backSquat.name = "Renamed"
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        #expect(backSquat.name == "Renamed")
    }

    // MARK: - Active session modality reconciliation

    private func makeSession(
        movementId: String,
        modality: EquipmentType,
        weight: Int?,
        status: ActiveSessionStatus = .active
    ) -> ActiveSession {
        let item = ActiveSessionItem(
            movementId: movementId,
            effectiveMovementId: movementId,
            selectedModality: modality,
            plannedSets: 3,
            plannedReps: 10,
            actualWeight: weight,
            actualReps: nil,
            rpe: nil,
            status: .notStarted,
            notes: nil
        )
        let block = ActiveSessionBlock(
            type: .single,
            order: 0,
            currentRound: 1,
            roundsCompleted: 0,
            items: [item]
        )
        return ActiveSession(plannedSessionId: "plan-1", status: status, blocks: [block])
    }

    @Test func reseedRepairsInvalidModalityInActiveSessions() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        // reverse-hyper is machine-only as of seed v5
        context.insert(makeSession(movementId: "reverse-hyper", modality: .dumbbells, weight: 25))
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let session = try #require(try context.fetch(FetchDescriptor<ActiveSession>()).first)
        #expect(session.blocks.first?.items.first?.selectedModality == .machine)
    }

    @Test func bodyweightFallbackZeroesWeight() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        // push-up allows bodyweight only
        context.insert(makeSession(movementId: "push-up", modality: .barbell, weight: 100))
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let session = try #require(try context.fetch(FetchDescriptor<ActiveSession>()).first)
        let item = try #require(session.blocks.first?.items.first)
        #expect(item.selectedModality == .bodyweight)
        #expect(item.actualWeight == 0)
    }

    @Test func validModalitySelectionIsPreserved() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        // kettlebell is an allowed modality for romanian-deadlift
        context.insert(makeSession(movementId: "romanian-deadlift", modality: .kettlebell, weight: 40))
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let session = try #require(try context.fetch(FetchDescriptor<ActiveSession>()).first)
        let item = try #require(session.blocks.first?.items.first)
        #expect(item.selectedModality == .kettlebell)
        #expect(item.actualWeight == 40)
    }

    @Test func completedSessionsAreNotModified() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let defaults = makeDefaults()
        context.insert(makeSession(movementId: "reverse-hyper", modality: .dumbbells, weight: 25, status: .completed))
        try context.save()

        MovementSeeder.seedIfNeeded(context: context, defaults: defaults)

        let session = try #require(try context.fetch(FetchDescriptor<ActiveSession>()).first)
        #expect(session.blocks.first?.items.first?.selectedModality == .dumbbells)
    }
}
