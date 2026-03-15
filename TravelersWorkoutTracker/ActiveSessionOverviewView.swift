import SwiftData
import SwiftUI

struct ActiveSessionOverviewView: View {
    let activeSession: ActiveSession

    var body: some View {
        ActiveSessionView(activeSession: activeSession)
    }
}

#Preview {
    NavigationStack {
        ActiveSessionOverviewView(activeSession: ActiveSession(plannedSessionId: "preview"))
    }
    .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self], inMemory: true)
}
