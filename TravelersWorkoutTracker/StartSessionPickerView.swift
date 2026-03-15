import SwiftData
import SwiftUI

struct StartSessionPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PlannedSession.lastPerformedDate, order: .reverse), SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]

    @State private var selectedPlannedSession: PlannedSession?
    @State private var activeSessionToOpen: ActiveSession?
    @State private var saveErrorMessage: String?

    var body: some View {
        List {
            if plannedSessions.isEmpty {
                ContentUnavailableView(
                    "No Planned Sessions",
                    systemImage: "play.square.stack",
                    description: Text("Create a planned session first, then come back here to begin a workout.")
                )
            } else {
                ForEach(plannedSessions) { plannedSession in
                    Button {
                        selectedPlannedSession = plannedSession
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(plannedSession.name)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            if let lastPerformedDate = plannedSession.lastPerformedDate {
                                Text("Last performed \(lastPerformedDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Never performed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Start Session")
        .navigationDestination(item: $activeSessionToOpen) { activeSession in
            ActiveSessionView(activeSession: activeSession)
        }
        .confirmationDialog(
            "Start Session",
            isPresented: Binding(
                get: { selectedPlannedSession != nil },
                set: { if !$0 { selectedPlannedSession = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Start in Standard Mode") {
                startSelectedSession(isTravelMode: false)
            }
            Button("Start in Travel Mode") {
                startSelectedSession(isTravelMode: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(selectedPlannedSession?.name ?? "")
        }
        .alert("Could Not Start Session", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private func startSelectedSession(isTravelMode: Bool) {
        guard let selectedPlannedSession else { return }

        do {
            activeSessionToOpen = try ActiveSessionFactory.createActiveSession(
                context: modelContext,
                from: selectedPlannedSession,
                isTravelMode: isTravelMode
            )
            self.selectedPlannedSession = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        StartSessionPickerView()
    }
    .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self], inMemory: true)
}
