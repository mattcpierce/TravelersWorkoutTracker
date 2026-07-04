import Foundation

enum MovementSubstitution {
    /// True when the movement can be performed with the equipment on hand.
    /// A nil equipment list means no restriction.
    static func fits(_ movement: Movement, availableEquipment: [EquipmentType]?) -> Bool {
        guard let availableEquipment else { return true }
        return movement.allowedModalities.contains(where: availableEquipment.contains)
    }

    /// Movements that can replace `movement` given the equipment on hand.
    /// Empty when the movement itself already fits. Same-category candidates
    /// rank first, then movements sharing at least one tag.
    static func substitutes(
        for movement: Movement,
        from allMovements: [Movement],
        availableEquipment: [EquipmentType],
        limit: Int = 3
    ) -> [Movement] {
        guard !fits(movement, availableEquipment: availableEquipment) else { return [] }

        let candidates = allMovements.filter { candidate in
            candidate.id != movement.id
                && fits(candidate, availableEquipment: availableEquipment)
        }

        let sameCategory = candidates
            .filter { $0.category == movement.category }
            .sorted { $0.name < $1.name }
        if sameCategory.count >= limit {
            return Array(sameCategory.prefix(limit))
        }

        let movementTags = Set(movement.tags)
        let tagMatches = candidates
            .filter { $0.category != movement.category && !movementTags.isDisjoint(with: $0.tags) }
            .sorted { $0.name < $1.name }

        return Array((sameCategory + tagMatches).prefix(limit))
    }
}
