import Foundation
import SwiftData

enum SessionBlockType: String, Codable, CaseIterable, Identifiable {
    case single
    case alternating

    var id: String { rawValue }
}

struct SessionBlockItem: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var movementId: String
    var plannedSets: Int
    var plannedReps: Int
    var notes: String?
    var blockPosition: Int
}

struct SessionBlock: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var type: SessionBlockType
    var order: Int
    var items: [SessionBlockItem]
}

@Model
final class PlannedSession {
    @Attribute(.unique) var id: String
    var name: String
    @Attribute(.externalStorage) var blocks: [SessionBlock]
    var lastPerformedDate: Date?

    init(
        id: String = UUID().uuidString,
        name: String,
        blocks: [SessionBlock] = [],
        lastPerformedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.lastPerformedDate = lastPerformedDate
    }
}
