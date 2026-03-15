// RootTabView.swift
// Updated in v2: restored tab navigation
import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                PlannedSessionsListView()
            }
            .tabItem {
                Label("Planned", systemImage: "square.stack.3d.up")
            }

            NavigationStack {
                SessionHistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
            }

            NavigationStack {
                MovementListView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self, WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self], inMemory: true)
}
