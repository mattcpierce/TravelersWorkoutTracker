// WorkoutSession.swift
import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: String
    var date: Date
    var templateId: String
    @Relationship(deleteRule: .cascade) var sessionExercises: [SessionExercise]

    init(
        id: String = UUID().uuidString,
        date: Date = .now,
        templateId: String,
        sessionExercises: [SessionExercise] = []
    ) {
        self.id = id
        self.date = date
        self.templateId = templateId
        self.sessionExercises = sessionExercises
    }
}
