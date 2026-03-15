import SwiftData
import SwiftUI

struct ExerciseSessionHistoryView: View {
    @Query(sort: [SortDescriptor(\ActiveSession.completedAt, order: .reverse), SortDescriptor(\ActiveSession.startTime, order: .reverse)]) private var sessions: [ActiveSession]
    @Query(sort: [SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]

    let movement: Movement

    private var plannedSessionLookup: [String: PlannedSession] {
        Dictionary(uniqueKeysWithValues: plannedSessions.map { ($0.id, $0) })
    }

    private var entries: [(session: ActiveSession, entry: ActiveSessionHistoryEntry)] {
        sessions
            .filter { $0.status == .completed }
            .compactMap { session in
                guard let entry = ActiveSessionHistorySupport.flattenedEntries(for: session).first(where: {
                    $0.movementId == movement.id && $0.status == .completed && $0.rpe != nil
                }) else {
                    return nil
                }
                return (session, entry)
            }
            .sorted {
                ActiveSessionHistorySupport.completedDate(for: $0.session) > ActiveSessionHistorySupport.completedDate(for: $1.session)
            }
    }

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No History Yet",
                    systemImage: "clock.badge.xmark",
                    description: Text("Complete this movement in a session to see history here.")
                )
            } else {
                ForEach(entries, id: \.entry.id) { item in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Modality: \(item.entry.modality.label)")
                            Text("Round \(item.entry.roundNumber) • Planned \(item.entry.plannedSets)x\(item.entry.plannedReps)")
                            Text("Actual reps: \(item.entry.actualReps ?? item.entry.plannedReps)   Weight: \(item.entry.actualWeight ?? 0)")
                            if let rpe = item.entry.rpe {
                                Text("RPE: \(rpe)")
                            }
                            if let notes = item.entry.notes, !notes.isEmpty {
                                Text("Notes: \(notes)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ActiveSessionHistorySupport.completedDate(for: item.session).formatted(date: .abbreviated, time: .shortened))
                            Text(plannedSessionLookup[item.session.plannedSessionId]?.name ?? "Unknown Planned Session")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Movement History")
    }
}
