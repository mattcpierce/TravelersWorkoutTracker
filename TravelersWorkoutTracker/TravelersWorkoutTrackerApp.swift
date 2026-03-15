//
//  TravelersWorkoutTrackerApp.swift
//  TravelersWorkoutTracker
//
//  Created by Matt Pierce on 2/22/26.
//
// Updated in v2: removed JSON loader logic; now using SwiftData MovementSeeder

import SwiftUI
import SwiftData

@main
struct TravelersWorkoutTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(
            for: [Movement.self, PlannedSession.self, ActiveSession.self, WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self],
            onSetup: { result in
                guard case let .success(container) = result else { return }
                MovementSeeder.seedIfNeeded(context: ModelContext(container))
            }
        )
    }
}
