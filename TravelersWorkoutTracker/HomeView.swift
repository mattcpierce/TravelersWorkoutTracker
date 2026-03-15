import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ActiveSession.startTime, order: .reverse)]) private var activeSessions: [ActiveSession]
    @Query(sort: [SortDescriptor(\PlannedSession.lastPerformedDate, order: .reverse), SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]
    @State private var saveErrorMessage: String?

    private var activeSessionList: [ActiveSession] {
        activeSessions.filter { $0.status == .active }
    }

    private var recentPlannedSessions: [PlannedSession] {
        Array(plannedSessions.prefix(3))
    }

    private var completedSessions: [ActiveSession] {
        activeSessions
            .filter { $0.status == .completed }
            .sorted { ActiveSessionHistorySupport.completedDate(for: $0) > ActiveSessionHistorySupport.completedDate(for: $1) }
    }

    private var recentWorkoutSessions: [ActiveSession] {
        Array(completedSessions.prefix(5))
    }

    private var sessionsThisMonth: Int {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: .now) else { return 0 }
        return completedSessions.filter { monthInterval.contains(ActiveSessionHistorySupport.completedDate(for: $0)) }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink {
                    StartSessionPickerView()
                } label: {
                    homeCard(title: "Start Session", subtitle: "Choose a planned session and launch it in standard or travel mode.", systemImage: "play.circle.fill")
                }
                .buttonStyle(.plain)

                summaryCard

                sectionCard(title: "Active Sessions") {
                    if activeSessionList.isEmpty {
                        Text("No active sessions.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activeSessionList) { activeSession in
                            activeSessionRow(activeSession)
                        }
                    }
                }

                sectionCard(title: "Recently Used Planned Sessions") {
                    if recentPlannedSessions.isEmpty {
                        Text("No planned sessions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentPlannedSessions) { session in
                            NavigationLink(session.name) {
                                PlannedSessionDetailView(plannedSession: session)
                            }
                        }
                    }
                }

                sectionCard(title: "Recent Workout History") {
                    if recentWorkoutSessions.isEmpty {
                        Text("No workout history yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentWorkoutSessions) { session in
                            NavigationLink {
                                SessionHistoryDetailView(session: session)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plannedSessions.first(where: { $0.id == session.plannedSessionId })?.name ?? "Workout Session")
                                        .font(.headline)
                                    Text(ActiveSessionHistorySupport.completedDate(for: session).formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Home")
        .alert("Could Not Save", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
    }

    private var summaryCard: some View {
        sectionCard(title: "This Month") {
            Text("\(sessionsThisMonth)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("completed sessions")
                .foregroundStyle(.secondary)
        }
    }

    private func homeCard(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func activeSessionRow(_ activeSession: ActiveSession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plannedSessions.first(where: { $0.id == activeSession.plannedSessionId })?.name ?? "Active Session")
                    .font(.headline)
                Text(activeSession.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            NavigationLink {
                ActiveSessionView(activeSession: activeSession)
            } label: {
                Text("Resume")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button("Complete") {
                completeSession(activeSession)
            }
            .tint(.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                deleteSession(activeSession)
            }
        }
    }

    private func completeSession(_ activeSession: ActiveSession) {
        activeSession.status = .completed
        activeSession.completedAt = .now
        plannedSessions.first(where: { $0.id == activeSession.plannedSessionId })?.lastPerformedDate = .now
        persistChanges()
    }

    private func deleteSession(_ activeSession: ActiveSession) {
        modelContext.delete(activeSession)
        persistChanges()
    }

    private func persistChanges() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self, WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self], inMemory: true)
}
