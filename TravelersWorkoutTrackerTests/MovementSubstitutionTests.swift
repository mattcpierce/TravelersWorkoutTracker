import Foundation
import Testing
@testable import TravelersWorkoutTracker

@MainActor
struct MovementSubstitutionTests {
    private func movement(
        id: String,
        category: String = "Squat",
        tags: [String] = [],
        modalities: [EquipmentType]
    ) -> Movement {
        Movement(id: id, name: id, description: "test", category: category, tags: tags, allowedModalities: modalities)
    }

    @Test func fitsWithNilEquipmentIsAlwaysTrue() {
        let barbellOnly = movement(id: "back-squat", modalities: [.barbell])
        #expect(MovementSubstitution.fits(barbellOnly, availableEquipment: nil))
        #expect(!MovementSubstitution.fits(barbellOnly, availableEquipment: [.dumbbells]))
        #expect(MovementSubstitution.fits(barbellOnly, availableEquipment: [.barbell, .dumbbells]))
    }

    @Test func noSubstitutesWhenMovementAlreadyFits() {
        let goblet = movement(id: "goblet-squat", modalities: [.dumbbells, .kettlebell])
        let others = [movement(id: "leg-press", modalities: [.machine])]
        #expect(MovementSubstitution.substitutes(for: goblet, from: others, availableEquipment: [.dumbbells]).isEmpty)
    }

    @Test func sameCategorySubstitutesRankFirst() {
        let backSquat = movement(id: "back-squat", tags: ["quads"], modalities: [.barbell])
        let all = [
            backSquat,
            movement(id: "goblet-squat", modalities: [.dumbbells]),
            movement(id: "leg-extension", category: "Isolation", tags: ["quads"], modalities: [.machine]),
            movement(id: "bench-press", category: "Horizontal Push", tags: ["chest"], modalities: [.dumbbells])
        ]

        let result = MovementSubstitution.substitutes(for: backSquat, from: all, availableEquipment: [.dumbbells, .machine])

        #expect(result.map(\.id) == ["goblet-squat", "leg-extension"])
    }

    @Test func excludesCandidatesThatDoNotFitEquipment() {
        let backSquat = movement(id: "back-squat", modalities: [.barbell])
        let all = [
            backSquat,
            movement(id: "front-squat", modalities: [.barbell]),
            movement(id: "goblet-squat", modalities: [.dumbbells])
        ]

        let result = MovementSubstitution.substitutes(for: backSquat, from: all, availableEquipment: [.dumbbells])

        #expect(result.map(\.id) == ["goblet-squat"])
    }

    @Test func respectsLimit() {
        let backSquat = movement(id: "back-squat", modalities: [.barbell])
        let all = [backSquat] + (1...5).map { movement(id: "sub-\($0)", modalities: [.dumbbells]) }

        let result = MovementSubstitution.substitutes(for: backSquat, from: all, availableEquipment: [.dumbbells], limit: 2)

        #expect(result.count == 2)
    }
}
