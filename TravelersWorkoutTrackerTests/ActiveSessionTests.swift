import Foundation
import SwiftData
import Testing
@testable import TravelersWorkoutTracker

@MainActor
@Suite(.serialized)
struct ActiveSessionTests {
    private func makeItem(plannedSets: Int = 3) -> ActiveSessionItem {
        ActiveSessionItem(
            movementId: "movement",
            effectiveMovementId: "movement",
            selectedModality: .barbell,
            plannedSets: plannedSets,
            plannedReps: 10,
            actualWeight: nil,
            actualReps: nil,
            rpe: nil,
            status: .notStarted,
            notes: nil
        )
    }

    private func makeLog(round: Int, weight: Int?, reps: Int?, rpe: Int? = nil) -> ActiveSessionRoundLog {
        ActiveSessionRoundLog(roundNumber: round, actualWeight: weight, actualReps: reps, rpe: rpe, status: .completed, notes: nil)
    }

    // MARK: - ActiveSessionItem.upsertLog

    @Test func upsertLogKeepsLogsSortedByRound() {
        var item = makeItem()
        item.upsertLog(makeLog(round: 2, weight: 50, reps: 8))
        item.upsertLog(makeLog(round: 1, weight: 45, reps: 10))
        #expect(item.roundLogs.map(\.roundNumber) == [1, 2])
    }

    @Test func upsertLogReplacesExistingRound() {
        var item = makeItem()
        item.upsertLog(makeLog(round: 1, weight: 45, reps: 10))
        item.upsertLog(makeLog(round: 1, weight: 50, reps: 8))
        #expect(item.roundLogs.count == 1)
        #expect(item.roundLogs.first?.actualWeight == 50)
    }

    @Test func upsertLogRollsUpFromHighestRound() {
        var item = makeItem()
        item.upsertLog(makeLog(round: 2, weight: 55, reps: 6, rpe: 8))
        item.upsertLog(makeLog(round: 1, weight: 45, reps: 10, rpe: 6))
        #expect(item.actualWeight == 55)
        #expect(item.actualReps == 6)
        #expect(item.rpe == 8)
        #expect(item.status == .completed)
    }

    // MARK: - ActiveSessionBlock

    @Test func totalRoundsIsMaxPlannedSetsAcrossItems() {
        let block = ActiveSessionBlock(
            type: .alternating,
            order: 0,
            currentRound: 1,
            roundsCompleted: 0,
            items: [makeItem(plannedSets: 3), makeItem(plannedSets: 5)]
        )
        #expect(block.totalRounds == 5)
        #expect(!block.isFinished)
    }

    @Test func itemsForCurrentRoundExcludesItemsWithFewerSets() {
        var block = ActiveSessionBlock(
            type: .alternating,
            order: 0,
            currentRound: 4,
            roundsCompleted: 3,
            items: [makeItem(plannedSets: 3), makeItem(plannedSets: 5)]
        )
        #expect(block.itemsForCurrentRound().count == 1)
        block.roundsCompleted = 5
        #expect(block.isFinished)
    }

    // MARK: - ActiveSessionFactory

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Movement.self, PlannedSession.self, ActiveSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func seedTestMovements(into context: ModelContext) throws {
        context.insert(Movement(
            id: "bench",
            name: "Bench",
            description: "test",
            hotelAlternativeMovementId: "floor-press",
            allowedModalities: [.barbell, .dumbbells]
        ))
        context.insert(Movement(
            id: "floor-press",
            name: "Floor Press",
            description: "test",
            allowedModalities: [.dumbbells]
        ))
        context.insert(Movement(
            id: "squat",
            name: "Squat",
            description: "test",
            allowedModalities: [.barbell]
        ))
        try context.save()
    }

    private func makePlannedSession(movementIds: [String]) -> PlannedSession {
        let items = movementIds.enumerated().map { index, movementId in
            SessionBlockItem(movementId: movementId, plannedSets: 4, plannedReps: 6, notes: nil, blockPosition: index)
        }
        return PlannedSession(name: "Test Plan", blocks: [SessionBlock(type: .single, order: 0, items: items)])
    }

    @Test func factoryUsesOriginalMovementWhenNotTraveling() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try seedTestMovements(into: context)
        let plan = makePlannedSession(movementIds: ["bench"])
        context.insert(plan)

        let session = try ActiveSessionFactory.createActiveSession(context: context, from: plan, isTravelMode: false)

        let item = try #require(session.blocks.first?.items.first)
        #expect(item.effectiveMovementId == "bench")
        #expect(item.selectedModality == .barbell)
        #expect(item.plannedSets == 4)
        #expect(item.plannedReps == 6)
    }

    @Test func factorySubstitutesHotelAlternativeInTravelMode() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try seedTestMovements(into: context)
        let plan = makePlannedSession(movementIds: ["bench"])
        context.insert(plan)

        let session = try ActiveSessionFactory.createActiveSession(context: context, from: plan, isTravelMode: true)

        let item = try #require(session.blocks.first?.items.first)
        #expect(item.movementId == "bench")
        #expect(item.effectiveMovementId == "floor-press")
        #expect(item.selectedModality == .dumbbells)
    }

    @Test func travelModeKeepsMovementWithoutAlternative() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try seedTestMovements(into: context)
        let plan = makePlannedSession(movementIds: ["squat"])
        context.insert(plan)

        let session = try ActiveSessionFactory.createActiveSession(context: context, from: plan, isTravelMode: true)

        let item = try #require(session.blocks.first?.items.first)
        #expect(item.effectiveMovementId == "squat")
        #expect(item.selectedModality == .barbell)
    }

    @Test func factorySortsBlocksAndItemsByOrder() throws {
        let container = try makeContainer()
        let context = container.mainContext
        try seedTestMovements(into: context)
        let plan = PlannedSession(name: "Unordered", blocks: [
            SessionBlock(type: .single, order: 1, items: [
                SessionBlockItem(movementId: "squat", plannedSets: 3, plannedReps: 5, notes: nil, blockPosition: 0)
            ]),
            SessionBlock(type: .alternating, order: 0, items: [
                SessionBlockItem(movementId: "floor-press", plannedSets: 3, plannedReps: 10, notes: nil, blockPosition: 1),
                SessionBlockItem(movementId: "bench", plannedSets: 3, plannedReps: 10, notes: nil, blockPosition: 0)
            ])
        ])
        context.insert(plan)

        let session = try ActiveSessionFactory.createActiveSession(context: context, from: plan, isTravelMode: false)

        #expect(session.blocks.map(\.order) == [0, 1])
        #expect(session.blocks.first?.items.map(\.movementId) == ["bench", "floor-press"])
        #expect(session.blocks.last?.items.first?.movementId == "squat")
    }
}
