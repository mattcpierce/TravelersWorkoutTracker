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
    private static let cloudKitContainerId = "iCloud.com.luckynumberthirteen.TravelersWorkout"

    let container: ModelContainer

    init() {
        let schema = Schema([
            Movement.self,
            PlannedSession.self,
            ActiveSession.self,
            WorkoutTemplate.self,
            WorkoutSession.self,
            SessionExercise.self
        ])

        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(Self.cloudKitContainerId)
            )
            container = try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch {
            // CloudKit container creation can fail (no iCloud account, missing
            // entitlement in some build contexts); fall back to the local store
            // rather than making the app unusable.
            do {
                let localConfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localConfiguration])
            } catch {
                fatalError("Could not create any ModelContainer: \(error)")
            }
        }

        MovementSeeder.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
