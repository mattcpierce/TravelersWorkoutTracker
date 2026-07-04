import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ActiveSession.startTime, order: .reverse)]) private var activeSessions: [ActiveSession]
    @Query(sort: [SortDescriptor(\PlannedSession.lastPerformedDate, order: .reverse), SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]
    @State private var saveErrorMessage: String?
    @State private var backupDocument: WorkoutBackupDocument?
    @State private var showingBackupExporter = false
    @State private var showingRestoreImporter = false
    @State private var pendingRestoreBackup: WorkoutBackup?
    @State private var restoreSummary: String?

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
                            ActiveSessionSwipeRow(
                                title: plannedSessions.first(where: { $0.id == activeSession.plannedSessionId })?.name ?? "Active Session",
                                subtitle: activeSession.startTime.formatted(date: .abbreviated, time: .shortened),
                                onCancel: { cancelSession(activeSession) }
                            ) {
                                NavigationLink {
                                    ActiveSessionView(activeSession: activeSession)
                                } label: {
                                    Text("Resume")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .buttonStyle(.borderedProminent)
                            }
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

                Text(appVersionText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        exportBackup()
                    } label: {
                        Label("Back Up Data", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingRestoreImporter = true
                    } label: {
                        Label("Restore from Backup", systemImage: "square.and.arrow.down")
                    }
                } label: {
                    Label("Data", systemImage: "externaldrive")
                }
            }
        }
        .fileExporter(
            isPresented: $showingBackupExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: WorkoutBackupService.defaultFilename()
        ) { result in
            if case .failure(let error) = result {
                saveErrorMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $showingRestoreImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                loadBackup(from: url)
            case .failure(let error):
                saveErrorMessage = error.localizedDescription
            }
        }
        .confirmationDialog(
            "Restore Backup",
            isPresented: Binding(
                get: { pendingRestoreBackup != nil },
                set: { if !$0 { pendingRestoreBackup = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Merge with Existing Data") { performRestore(.merge) }
            Button("Replace All Data", role: .destructive) { performRestore(.replace) }
            Button("Cancel", role: .cancel) { pendingRestoreBackup = nil }
        } message: {
            if let backup = pendingRestoreBackup {
                Text("Backup from \(backup.exportedAt.formatted(date: .abbreviated, time: .shortened)) with \(backup.movements.count) movements and \(backup.plannedSessions.count) planned sessions. Merge keeps data not in the backup; Replace deletes everything first.")
            }
        }
        .alert("Restore Complete", isPresented: Binding(
            get: { restoreSummary != nil },
            set: { if !$0 { restoreSummary = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreSummary ?? "")
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

    private var summaryCard: some View {
        sectionCard(title: "This Month") {
            Text("\(sessionsThisMonth)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("completed sessions")
                .foregroundStyle(.secondary)
        }
    }

    private func exportBackup() {
        do {
            backupDocument = WorkoutBackupDocument(data: try WorkoutBackupService.exportJSON(context: modelContext))
            showingBackupExporter = true
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func loadBackup(from url: URL) {
        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            pendingRestoreBackup = try WorkoutBackupService.decodeBackup(from: Data(contentsOf: url))
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func performRestore(_ mode: WorkoutBackupService.RestoreMode) {
        guard let backup = pendingRestoreBackup else { return }
        pendingRestoreBackup = nil
        do {
            try WorkoutBackupService.restore(backup, into: modelContext, mode: mode)
            restoreSummary = "Restored \(backup.movements.count) movements, \(backup.plannedSessions.count) planned sessions, and \(backup.activeSessions.count + backup.workoutSessions.count) sessions."
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "Version \(version) (\(build))"
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

    private func cancelSession(_ activeSession: ActiveSession) {
        activeSession.status = .abandoned
        activeSession.completedAt = .now
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

private struct ActiveSessionSwipeRow<TrailingContent: View>: View {
    private let title: String
    private let subtitle: String
    private let onCancel: () -> Void
    private let trailingContent: TrailingContent

    @State private var dragOffset: CGFloat = 0

    private let actionWidth: CGFloat = 92

    init(
        title: String,
        subtitle: String,
        onCancel: @escaping () -> Void,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onCancel = onCancel
        self.trailingContent = trailingContent()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    dragOffset = 0
                }
                onCancel()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.headline)
                    Text("Cancel")
                        .font(.caption.weight(.semibold))
                }
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .tint(.red)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                trailingContent
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(Color(.secondarySystemBackground))
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        let translation = value.translation.width
                        guard translation <= 0 else {
                            dragOffset = min(0, dragOffset + translation / 12)
                            return
                        }

                        dragOffset = max(-actionWidth, translation)
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            dragOffset = value.translation.width < -(actionWidth * 0.45) ? -actionWidth : 0
                        }
                    }
            )
            .onTapGesture {
                if dragOffset != 0 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        dragOffset = 0
                    }
                }
            }
        }
        .clipped()
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self, WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self], inMemory: true)
}
