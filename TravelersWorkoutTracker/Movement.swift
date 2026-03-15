// Movement.swift
import Foundation
import SwiftData

@Model
final class Movement {
    @Attribute(.unique) var id: String
    var name: String
    private var movementDescription: String
    var category: String
    @Attribute(.externalStorage) var tags: [String]
    var hotelAlternativeMovementId: String?
    @Attribute(.externalStorage) var allowedModalities: [EquipmentType]
    var isCustom: Bool

    init(
        id: String,
        name: String,
        description: String,
        category: String = "General",
        tags: [String] = [],
        hotelAlternativeMovementId: String? = nil,
        allowedModalities: [EquipmentType] = EquipmentType.allCases,
        isCustom: Bool = false
    ) {
        self.id = id
        self.name = name
        self.movementDescription = description
        self.category = category
        self.tags = tags
        self.hotelAlternativeMovementId = hotelAlternativeMovementId
        self.allowedModalities = allowedModalities
        self.isCustom = isCustom
    }

    var description: String {
        get { movementDescription }
        set { movementDescription = newValue }
    }
}

enum EquipmentType: String, CaseIterable, Codable, Identifiable {
    case barbell
    case dumbbells
    case kettlebell
    case cable
    case machine
    case bodyweight
    case landmine
    case sled
    case treadmill
    case resistanceBand

    var id: String { rawValue }

    var label: String {
        switch self {
        case .resistanceBand:
            return "Bands"
        default:
            return rawValue.capitalized
        }
    }
}

struct TemplateMovement: Codable, Hashable, Identifiable, Equatable {
    var movementId: String
    var defaultEquipment: EquipmentType

    var id: String {
        "\(movementId)-\(defaultEquipment.rawValue)"
    }
}
