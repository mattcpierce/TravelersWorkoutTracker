// WorkoutSession.swift
import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: String = UUID().uuidString
    var date: Date = Date.now
    var templateId: String = ""
    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.workoutSession) var sessionExercises: [SessionExercise]?

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
