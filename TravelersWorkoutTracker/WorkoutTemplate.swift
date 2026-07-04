// WorkoutTemplate.swift
import Foundation
import SwiftData

@Model
class WorkoutTemplate {
    var id: String = UUID().uuidString

    var name: String = ""
    @Attribute(.externalStorage)
    var orderedMovements: [TemplateMovement] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        orderedMovements: [TemplateMovement] = []
    ) {
        self.id = id
        self.name = name
        self.orderedMovements = orderedMovements
    }
}
