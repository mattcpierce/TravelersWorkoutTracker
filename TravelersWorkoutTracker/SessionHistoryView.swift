import SwiftData
import SwiftUI

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ActiveSession.completedAt, order: .reverse), SortDescriptor(\ActiveSession.startTime, order: .reverse)]) private var sessions: [ActiveSession]
    @Query(sort: [SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]

    @State private var displayedMonth = Date()
    @State private var selectedDay: Int?
    @State private var searchText = ""
    @State private var selectedPlannedSessionId: String?
    @State private var saveErrorMessage: String?

    private let calendar = Calendar.current

    private var completedSessions: [ActiveSession] {
        sessions.filter { $0.status == .completed }
    }

    private var plannedSessionLookup: [String: PlannedSession] {
        Dictionary(uniqueKeysWithValues: plannedSessions.map { ($0.id, $0) })
    }

    private var selectedMonthInterval: DateInterval {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
        return calendar.dateInterval(of: .month, for: start) ?? DateInterval(start: start, duration: 0)
    }

    private var sessionsInMonth: [ActiveSession] {
        completedSessions.filter { selectedMonthInterval.contains(ActiveSessionHistorySupport.completedDate(for: $0)) }
    }

    private var workoutCountByDay: [Int: Int] {
        var counts: [Int: Int] = [:]
        for session in sessionsInMonth {
            let day = calendar.component(.day, from: ActiveSessionHistorySupport.completedDate(for: session))
            counts[day, default: 0] += 1
        }
        return counts
    }

    private var filteredSessions: [ActiveSession] {
        sessionsInMonth.filter { session in
            let sessionName = plannedSessionLookup[session.plannedSessionId]?.name ?? "Unknown Planned Session"
            let matchesSearch = ActiveSessionHistorySupport.sessionMatchesSearch(session, plannedSessionName: sessionName, query: searchText)
            let matchesPlannedSession = selectedPlannedSessionId == nil || session.plannedSessionId == selectedPlannedSessionId
            let matchesDay = selectedDay == nil || calendar.component(.day, from: ActiveSessionHistorySupport.completedDate(for: session)) == selectedDay
            return matchesSearch && matchesPlannedSession && matchesDay
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                AnimatedCalendarView(
                    displayedMonth: displayedMonth,
                    selectedDay: selectedDay,
                    workoutCountByDay: workoutCountByDay,
                    onPreviousMonth: moveToPreviousMonth,
                    onNextMonth: moveToNextMonth,
                    onSelectDay: { selectedDay = $0 }
                )

                historyFilterBar
            }
            .padding(.horizontal)

            List {
                if filteredSessions.isEmpty {
                    ContentUnavailableView(
                        "No Session History",
                        systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                        description: Text("No completed sessions match your current month or filters.")
                    )
                } else {
                    ForEach(filteredSessions) { session in
                        NavigationLink {
                            SessionHistoryDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plannedSessionLookup[session.plannedSessionId]?.name ?? "Unknown Planned Session")
                                    .font(.headline)
                                Text(ActiveSessionHistorySupport.completedDate(for: session).formatted(date: .abbreviated, time: .shortened))
                                Text("\(ActiveSessionHistorySupport.flattenedEntries(for: session).count) logged exercises")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                deleteSession(session)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Session History")
        .alert("Could Not Save", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private var historyFilterBar: some View {
        VStack(spacing: 8) {
            TextField("Search session name", text: $searchText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Menu {
                    Button("All Planned Sessions") {
                        selectedPlannedSessionId = nil
                    }

                    Divider()

                    ForEach(plannedSessions) { session in
                        Button {
                            selectedPlannedSessionId = session.id
                        } label: {
                            if selectedPlannedSessionId == session.id {
                                Label(session.name, systemImage: "checkmark")
                            } else {
                                Text(session.name)
                            }
                        }
                    }
                } label: {
                    Label(selectedPlannedSessionLabel, systemImage: "line.3.horizontal.decrease.circle")
                }

                Spacer()

                if selectedDay != nil || selectedPlannedSessionId != nil || !searchText.isEmpty {
                    Button("Clear") {
                        selectedDay = nil
                        selectedPlannedSessionId = nil
                        searchText = ""
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var selectedPlannedSessionLabel: String {
        if let selectedPlannedSessionId,
           let plannedSession = plannedSessions.first(where: { $0.id == selectedPlannedSessionId }) {
            return plannedSession.name
        }
        return "All Planned Sessions"
    }

    private func moveToPreviousMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDay = nil
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }

    private func moveToNextMonth() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDay = nil
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }

    private func deleteSession(_ session: ActiveSession) {
        modelContext.delete(session)
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

struct SessionHistoryDetailView: View {
    @Query(sort: [SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]

    let session: ActiveSession

    private var plannedSession: PlannedSession? {
        plannedSessions.first { $0.id == session.plannedSessionId }
    }

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })
    }

    private var entries: [ActiveSessionHistoryEntry] {
        ActiveSessionHistorySupport.flattenedEntries(for: session)
    }

    var body: some View {
        List {
            Section("Session") {
                Text(ActiveSessionHistorySupport.completedDate(for: session).formatted(date: .complete, time: .shortened))
                Text(plannedSession?.name ?? "Unknown Planned Session")
                    .foregroundStyle(.secondary)
                Text(session.isTravelMode ? "Travel Mode" : "Standard Mode")
                    .foregroundStyle(.secondary)
            }

            if entries.isEmpty {
                Section("Logged Exercises") {
                    Text("No logged exercises")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(Array(Dictionary(grouping: entries, by: \.blockId).values).sorted { lhs, rhs in
                    (lhs.first?.blockOrder ?? 0) < (rhs.first?.blockOrder ?? 0)
                }, id: \.self) { blockEntries in
                    let block = blockEntries.first
                    Section(header: Text(block?.blockType == .alternating ? "Alternating Block" : "Single Exercise Block")) {
                        ForEach(blockEntries.sorted { lhs, rhs in
                            if lhs.roundNumber == rhs.roundNumber {
                                return lhs.id < rhs.id
                            }
                            return lhs.roundNumber < rhs.roundNumber
                        }) { entry in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(movementLookup[entry.movementId]?.name ?? "Unknown Movement")
                                    .font(.headline)
                                Text(entry.modality.label)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Planned: \(entry.plannedSets)x\(entry.plannedReps)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Actual reps: \(entry.actualReps ?? entry.plannedReps)   Weight: \(entry.actualWeight ?? 0)")
                                    .font(.subheadline)
                                Text("Status: \(entry.status.rawValue.capitalized)")
                                    .font(.subheadline)
                                if let rpe = entry.rpe {
                                    Text("RPE: \(rpe)")
                                        .font(.subheadline)
                                }
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Details")
    }
}
