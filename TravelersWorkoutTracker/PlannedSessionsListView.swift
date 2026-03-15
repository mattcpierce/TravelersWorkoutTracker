import SwiftData
import SwiftUI

struct PlannedSessionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]

    @State private var searchText = ""
    @State private var showingNewSessionSheet = false
    @State private var sessionToStart: PlannedSession?
    @State private var newlyCreatedSession: PlannedSession?
    @State private var activeSessionToOpen: ActiveSession?
    @State private var shouldNavigateToCreatedSession = false
    @State private var saveErrorMessage: String?

    private var filteredSessions: [PlannedSession] {
        if searchText.isEmpty { return plannedSessions }
        return plannedSessions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            if filteredSessions.isEmpty {
                ContentUnavailableView(
                    "No Planned Sessions",
                    systemImage: "calendar.badge.plus",
                    description: Text("Create a planned session to start building your training week.")
                )
            } else {
                ForEach(filteredSessions) { plannedSession in
                    NavigationLink {
                        PlannedSessionDetailView(plannedSession: plannedSession)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plannedSession.name)
                                .font(.headline)
                            Text(summaryText(for: plannedSession))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Duplicate") {
                            duplicate(plannedSession)
                        }
                        .tint(.blue)

                        Button("Start") {
                            sessionToStart = plannedSession
                        }
                        .tint(.green)

                        Button("Delete", role: .destructive) {
                            delete(plannedSession)
                        }
                    }
                }
            }
        }
        .navigationTitle("Planned Sessions")
        .searchable(text: $searchText, prompt: "Search planned sessions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Session") {
                    showingNewSessionSheet = true
                }
            }
        }
        .sheet(isPresented: $showingNewSessionSheet) {
            NewPlannedSessionView { sessionName in
                createSession(named: sessionName)
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToCreatedSession) {
            if let newlyCreatedSession {
                PlannedSessionDetailView(plannedSession: newlyCreatedSession)
            } else {
                Text("Planned session unavailable")
            }
        }
        .navigationDestination(item: $activeSessionToOpen) { activeSession in
            ActiveSessionView(activeSession: activeSession)
        }
        .confirmationDialog(
            "Start Session",
            isPresented: Binding(
                get: { sessionToStart != nil },
                set: { if !$0 { sessionToStart = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Standard Mode") {
                startSelectedSession(isTravelMode: false)
            }
            Button("Travel Mode") {
                startSelectedSession(isTravelMode: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(sessionToStart?.name ?? "")
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private func summaryText(for plannedSession: PlannedSession) -> String {
        let blockCount = plannedSession.blocks.count
        if let lastPerformedDate = plannedSession.lastPerformedDate {
            return "\(blockCount) blocks • Last performed \(lastPerformedDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return "\(blockCount) blocks • Never performed"
    }

    private func createSession(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let plannedSession = PlannedSession(name: trimmed)
        modelContext.insert(plannedSession)

        do {
            try modelContext.save()
            newlyCreatedSession = plannedSession
            shouldNavigateToCreatedSession = true
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func duplicate(_ plannedSession: PlannedSession) {
        let copy = PlannedSession(
            name: "\(plannedSession.name) Copy",
            blocks: plannedSession.blocks,
            lastPerformedDate: plannedSession.lastPerformedDate
        )
        modelContext.insert(copy)

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func delete(_ plannedSession: PlannedSession) {
        modelContext.delete(plannedSession)

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func startSelectedSession(isTravelMode: Bool) {
        guard let sessionToStart else { return }
        do {
            activeSessionToOpen = try ActiveSessionFactory.createActiveSession(
                context: modelContext,
                from: sessionToStart,
                isTravelMode: isTravelMode
            )
            self.sessionToStart = nil
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

struct NewPlannedSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var plannedSessionName = ""

    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Session Name", text: $plannedSessionName)
            }
            .navigationTitle("New Planned Session")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(plannedSessionName)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlannedSessionsListView()
    }
    .modelContainer(for: [PlannedSession.self, ActiveSession.self], inMemory: true)
}
