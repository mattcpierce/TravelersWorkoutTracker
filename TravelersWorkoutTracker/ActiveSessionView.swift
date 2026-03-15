import SwiftData
import SwiftUI

struct ActiveSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var activeSession: ActiveSession

    @Query(sort: [SortDescriptor(\ActiveSession.completedAt, order: .reverse), SortDescriptor(\ActiveSession.startTime, order: .reverse)]) private var allSessions: [ActiveSession]
    @Query(sort: [SortDescriptor(\PlannedSession.name)]) private var plannedSessions: [PlannedSession]
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]

    @State private var drafts: [String: ActiveSessionDraft] = [:]
    @State private var infoMovement: Movement?
    @State private var rpeTarget: RPETarget?
    @State private var exerciseChangeTarget: ExerciseChangeTarget?
    @State private var expandedItemID: String?
    @State private var expandedResolvedBlockID: String?
    @State private var saveErrorMessage: String?

    private var plannedSession: PlannedSession? {
        plannedSessions.first { $0.id == activeSession.plannedSessionId }
    }

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })
    }

    private var orderedBlocks: [ActiveSessionBlock] {
        activeSession.blocks.sorted { $0.order < $1.order }
    }

    private var canFinishSession: Bool {
        !orderedBlocks.isEmpty && orderedBlocks.allSatisfy(isBlockResolved)
    }

    private var duplicatedTravelEffectiveMovementIds: Set<String> {
        let substitutedIds = activeSession.blocks
            .flatMap(\.items)
            .filter { $0.effectiveMovementId != $0.movementId }
            .map(\.effectiveMovementId)

        let counts = Dictionary(substitutedIds.map { ($0, 1) }, uniquingKeysWith: +)
        return Set(counts.compactMap { $0.value > 1 ? $0.key : nil })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sessionSummaryCard

                if orderedBlocks.isEmpty {
                    ContentUnavailableView(
                        "No Session Blocks",
                        systemImage: "rectangle.stack.badge.exclamationmark",
                        description: Text("This planned session has no workout blocks yet.")
                    )
                } else {
                    ForEach(orderedBlocks) { block in
                        blockSection(for: block)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(plannedSession?.name ?? "Active Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    finishSession()
                }
                .disabled(!canFinishSession)
            }
        }
        .sheet(item: $infoMovement) { movement in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(movement.name)
                            .font(.title2.bold())
                        Text(movement.description)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .navigationTitle("Movement Info")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            infoMovement = nil
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $rpeTarget) { target in
            QuickRPEPickerSheet(
                selectedRPE: Binding(
                    get: { draft(for: target.blockId, itemId: target.itemId, round: target.round).rpe },
                    set: { newValue in
                        updateDraft(for: target.blockId, itemId: target.itemId, round: target.round) { draft in
                            draft.rpe = newValue
                        }
                    }
                )
            )
        }
        .confirmationDialog(
            "Change Exercise",
            isPresented: Binding(
                get: { exerciseChangeTarget != nil },
                set: { if !$0 { exerciseChangeTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let target = exerciseChangeTarget,
               let hotelAlternative = hotelAlternativeMovement(for: target.item) {
                Button("Use Hotel Alternative") {
                    applyExerciseChange(to: hotelAlternative.id, for: target)
                }
            }

            if exerciseChangeTarget != nil {
                Button("Use Planned Exercise") {
                    guard let target = exerciseChangeTarget else { return }
                    applyExerciseChange(to: target.item.movementId, for: target)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let target = exerciseChangeTarget {
                let currentName = displayedMovement(for: target.item)?.name ?? "Current Exercise"
                let plannedName = originalMovement(for: target.item)?.name ?? "Planned Exercise"
                Text("Current: \(currentName)\nPlanned: \(plannedName)")
            }
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

    private var sessionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activeSession.isTravelMode ? "Travel Mode" : "Standard Mode")
                .font(.headline)
            Text("Started \(activeSession.startTime.formatted(date: .abbreviated, time: .shortened))")
                .foregroundStyle(.secondary)
            Text(canFinishSession ? "All exercises are resolved. You can finish this session." : "Open each exercise, log what you did, then mark it Complete, Skip, or Incomplete.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func blockSection(for block: ActiveSessionBlock) -> some View {
        let blockResolved = isBlockResolved(block)
        let blockExpanded = isBlockExpanded(block)
        let visibleItems = block.items

        VStack(alignment: .leading, spacing: 12) {
            Button {
                toggleBlockExpansion(block)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(block.type == .single ? "Single Exercise Block" : "Alternating Block")
                            .font(.headline)
                        Text(blockResolved ? "All exercises resolved" : blockSummaryText(for: block))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if blockResolved {
                        Label("Done", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: blockExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if blockResolved && !blockExpanded {
                Text("Tap to review this block.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(visibleItems) { item in
                    if let movement = displayedMovement(for: item) {
                        let plannedMovement = originalMovement(for: item)
                        let itemExpanded = expandedItemID == item.id
                        let lastEntry = lastCompletedEntry(for: item)
                        ActiveSessionCardView(
                            title: movement.name,
                            plannedMovementName: plannedMovement?.name,
                            plannedSets: item.plannedSets,
                            plannedReps: item.plannedReps,
                            currentRound: nil,
                            isExpanded: itemExpanded,
                            modality: bindingForModality(blockId: block.id, itemId: item.id),
                            allowedModalities: movement.allowedModalities.isEmpty ? EquipmentType.allCases : movement.allowedModalities,
                            setsText: bindingForSetsText(blockId: block.id, itemId: item.id),
                            weightText: bindingForWeight(blockId: block.id, itemId: item.id, round: block.currentRound),
                            repsText: bindingForReps(blockId: block.id, itemId: item.id, round: block.currentRound),
                            notesText: bindingForNotes(blockId: block.id, itemId: item.id, round: block.currentRound),
                            selectedRPE: bindingForRPE(blockId: block.id, itemId: item.id, round: block.currentRound),
                            status: currentStatus(for: block.id, itemId: item.id, round: block.currentRound),
                            showsDuplicateTravelWarning: duplicatedTravelEffectiveMovementIds.contains(item.effectiveMovementId),
                            lastPerformanceSummary: lastEntry.map { ActiveSessionHistorySupport.summaryText(for: $0.entry) },
                            canUseLast: lastEntry != nil,
                            onInfoTap: { infoMovement = movement },
                            onChangeExercise: {
                                exerciseChangeTarget = ExerciseChangeTarget(blockId: block.id, item: item)
                            },
                            onToggleExpanded: {
                                toggleItemExpansion(item.id, within: block)
                            },
                            onUseLast: {
                                applyLastPerformance(for: item, in: block)
                            },
                            onSelectRPE: {
                                rpeTarget = RPETarget(blockId: block.id, itemId: item.id, round: block.currentRound)
                            },
                            onMarkComplete: {
                                recordStatus(.completed, for: block.id, itemId: item.id, round: block.currentRound)
                            },
                            onMarkSkipped: {
                                recordStatus(.skipped, for: block.id, itemId: item.id, round: block.currentRound)
                            },
                            onMarkIncomplete: {
                                recordStatus(.incomplete, for: block.id, itemId: item.id, round: block.currentRound)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func bindingForModality(blockId: String, itemId: String) -> Binding<EquipmentType> {
        Binding(
            get: { currentItem(blockId: blockId, itemId: itemId)?.selectedModality ?? .bodyweight },
            set: { newValue in
                updateItem(blockId: blockId, itemId: itemId) { item in
                    item.selectedModality = newValue
                    if newValue == .bodyweight {
                        item.actualWeight = 0
                    }
                }
                if newValue == .bodyweight {
                    updateDraft(for: blockId, itemId: itemId, round: 1) { draft in
                        draft.weightText = ""
                    }
                }
                persistChanges()
            }
        )
    }

    private func bindingForSetsText(blockId: String, itemId: String) -> Binding<String> {
        Binding(
            get: { String(currentItem(blockId: blockId, itemId: itemId)?.plannedSets ?? 0) },
            set: { newValue in
                let filteredValue = filteredNumeric(newValue)
                updateItem(blockId: blockId, itemId: itemId) { item in
                    item.plannedSets = max(Int(filteredValue) ?? 0, 0)
                }
                persistChanges()
            }
        )
    }

    private func bindingForWeight(blockId: String, itemId: String, round: Int) -> Binding<String> {
        Binding(
            get: { draft(for: blockId, itemId: itemId, round: round).weightText },
            set: { newValue in
                updateDraft(for: blockId, itemId: itemId, round: round) { draft in
                    draft.weightText = filteredNumeric(newValue)
                }
            }
        )
    }

    private func bindingForReps(blockId: String, itemId: String, round: Int) -> Binding<String> {
        Binding(
            get: { draft(for: blockId, itemId: itemId, round: round).repsText },
            set: { newValue in
                updateDraft(for: blockId, itemId: itemId, round: round) { draft in
                    draft.repsText = filteredNumeric(newValue)
                }
            }
        )
    }

    private func bindingForNotes(blockId: String, itemId: String, round: Int) -> Binding<String> {
        Binding(
            get: { draft(for: blockId, itemId: itemId, round: round).notesText },
            set: { newValue in
                updateDraft(for: blockId, itemId: itemId, round: round) { draft in
                    draft.notesText = newValue
                }
            }
        )
    }

    private func bindingForRPE(blockId: String, itemId: String, round: Int) -> Binding<Int?> {
        Binding(
            get: { draft(for: blockId, itemId: itemId, round: round).rpe },
            set: { newValue in
                updateDraft(for: blockId, itemId: itemId, round: round) { draft in
                    draft.rpe = newValue
                }
            }
        )
    }

    private func draft(for blockId: String, itemId: String, round: Int) -> ActiveSessionDraft {
        let key = draftKey(blockId: blockId, itemId: itemId, round: round)
        if let existing = drafts[key] {
            return existing
        }
        let item = currentItem(blockId: blockId, itemId: itemId)
        let log = item?.log(for: round)
        return ActiveSessionDraft(
            weightText: log?.actualWeight.map(String.init) ?? "",
            repsText: log?.actualReps.map(String.init) ?? String(item?.plannedReps ?? 0),
            notesText: log?.notes ?? item?.notes ?? "",
            rpe: log?.rpe
        )
    }

    private func updateDraft(for blockId: String, itemId: String, round: Int, mutate: (inout ActiveSessionDraft) -> Void) {
        let key = draftKey(blockId: blockId, itemId: itemId, round: round)
        var value = draft(for: blockId, itemId: itemId, round: round)
        mutate(&value)
        drafts[key] = value
    }

    private func currentStatus(for blockId: String, itemId: String, round: Int) -> ExerciseExecutionStatus {
        currentItem(blockId: blockId, itemId: itemId)?.status ?? .notStarted
    }

    private func recordStatus(_ status: ExerciseExecutionStatus, for blockId: String, itemId: String, round: Int) {
        let draft = draft(for: blockId, itemId: itemId, round: round)
        let selectedModality = currentItem(blockId: blockId, itemId: itemId)?.selectedModality ?? .bodyweight
        let log = ActiveSessionRoundLog(
            roundNumber: 1,
            actualWeight: selectedModality == .bodyweight ? 0 : Int(draft.weightText),
            actualReps: Int(draft.repsText),
            rpe: draft.rpe,
            status: status,
            notes: draft.notesText.nilIfBlank
        )

        updateItem(blockId: blockId, itemId: itemId) { item in
            item.upsertLog(log)
        }
        expandedItemID = nil
        if let block = orderedBlocks.first(where: { $0.id == blockId }), isBlockResolved(block) {
            expandedResolvedBlockID = nil
        }
        persistChanges()
    }

    private func finishSession() {
        activeSession.status = .completed
        activeSession.completedAt = .now
        plannedSession?.lastPerformedDate = .now
        persistChanges()
        dismiss()
    }

    private func currentItem(blockId: String, itemId: String) -> ActiveSessionItem? {
        activeSession.blocks.first(where: { $0.id == blockId })?.items.first(where: { $0.id == itemId })
    }

    private func updateBlock(blockId: String, mutate: (inout ActiveSessionBlock) -> Void) {
        var blocks = activeSession.blocks
        guard let blockIndex = blocks.firstIndex(where: { $0.id == blockId }) else { return }
        mutate(&blocks[blockIndex])
        activeSession.blocks = blocks
    }

    private func updateItem(blockId: String, itemId: String, mutate: (inout ActiveSessionItem) -> Void) {
        updateBlock(blockId: blockId) { block in
            guard let itemIndex = block.items.firstIndex(where: { $0.id == itemId }) else { return }
            mutate(&block.items[itemIndex])
        }
    }

    private func displayedMovement(for item: ActiveSessionItem) -> Movement? {
        movementLookup[item.effectiveMovementId] ?? movementLookup[item.movementId]
    }

    private func originalMovement(for item: ActiveSessionItem) -> Movement? {
        movementLookup[item.movementId]
    }

    private func hotelAlternativeMovement(for item: ActiveSessionItem) -> Movement? {
        guard let hotelAlternativeId = originalMovement(for: item)?.hotelAlternativeMovementId else { return nil }
        return movementLookup[hotelAlternativeId]
    }

    private func applyExerciseChange(to movementId: String, for target: ExerciseChangeTarget) {
        let allowedModalities = movementLookup[movementId]?.allowedModalities ?? []
        updateItem(blockId: target.blockId, itemId: target.item.id) { item in
            item.effectiveMovementId = movementId
            if !allowedModalities.isEmpty, !allowedModalities.contains(item.selectedModality) {
                item.selectedModality = allowedModalities.first ?? .bodyweight
            }
            if item.selectedModality == .bodyweight {
                item.actualWeight = 0
            }
        }
        if currentItem(blockId: target.blockId, itemId: target.item.id)?.selectedModality == .bodyweight {
            updateDraft(for: target.blockId, itemId: target.item.id, round: 1) { draft in
                draft.weightText = ""
            }
        }
        exerciseChangeTarget = nil
        persistChanges()
    }

    private func isBlockResolved(_ block: ActiveSessionBlock) -> Bool {
        !block.items.isEmpty && block.items.allSatisfy { $0.status != .notStarted }
    }

    private func blockSummaryText(for block: ActiveSessionBlock) -> String {
        let resolvedCount = block.items.filter { $0.status != .notStarted }.count
        return "\(resolvedCount) of \(block.items.count) exercises resolved"
    }

    private func isBlockExpanded(_ block: ActiveSessionBlock) -> Bool {
        if isBlockResolved(block) {
            return expandedResolvedBlockID == block.id
        }
        return true
    }

    private func toggleBlockExpansion(_ block: ActiveSessionBlock) {
        guard isBlockResolved(block) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedResolvedBlockID == block.id {
                expandedResolvedBlockID = nil
            } else {
                expandedResolvedBlockID = block.id
                expandedItemID = nil
            }
        }
    }

    private func toggleItemExpansion(_ itemID: String, within block: ActiveSessionBlock) {
        guard !isBlockResolved(block) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedResolvedBlockID = nil
            expandedItemID = expandedItemID == itemID ? nil : itemID
        }
    }

    private func lastCompletedEntry(for item: ActiveSessionItem) -> (session: ActiveSession, entry: ActiveSessionHistoryEntry)? {
        let movementID = item.effectiveMovementId
        return ActiveSessionHistorySupport.lastCompletedEntry(
            for: movementID,
            modality: item.selectedModality,
            in: allSessions,
            excludingSessionId: activeSession.id
        )
    }

    private func applyLastPerformance(for item: ActiveSessionItem, in block: ActiveSessionBlock) {
        guard let lastEntry = lastCompletedEntry(for: item) else { return }

        updateItem(blockId: block.id, itemId: item.id) { currentItem in
            currentItem.plannedSets = max(lastEntry.entry.plannedSets, 0)
            currentItem.plannedReps = max(lastEntry.entry.actualReps ?? lastEntry.entry.plannedReps, 0)
        }

        updateDraft(for: block.id, itemId: item.id, round: 1) { draft in
            draft.repsText = String(lastEntry.entry.actualReps ?? lastEntry.entry.plannedReps)
            draft.weightText = lastEntry.entry.modality == .bodyweight ? "" : String(lastEntry.entry.actualWeight ?? 0)
        }

        persistChanges()
    }

    private func persistChanges() {
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func filteredNumeric(_ value: String) -> String {
        String(value.filter(\.isNumber))
    }

    private func draftKey(blockId: String, itemId: String, round: Int) -> String {
        "\(blockId)-\(itemId)-\(round)"
    }
}

private struct ActiveSessionDraft {
    var weightText: String
    var repsText: String
    var notesText: String
    var rpe: Int?
}

private struct RPETarget: Identifiable {
    let blockId: String
    let itemId: String
    let round: Int

    var id: String { "\(blockId)-\(itemId)-\(round)" }
}

private struct ExerciseChangeTarget: Identifiable {
    let blockId: String
    let item: ActiveSessionItem

    var id: String { "\(blockId)-\(item.id)" }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ActiveSessionCardView: View {
    let title: String
    let plannedMovementName: String?
    let plannedSets: Int
    let plannedReps: Int
    let currentRound: Int?
    let isExpanded: Bool
    @Binding var modality: EquipmentType
    let allowedModalities: [EquipmentType]
    @Binding var setsText: String
    @Binding var weightText: String
    @Binding var repsText: String
    @Binding var notesText: String
    @Binding var selectedRPE: Int?
    let status: ExerciseExecutionStatus
    let showsDuplicateTravelWarning: Bool
    let lastPerformanceSummary: String?
    let canUseLast: Bool
    let onInfoTap: () -> Void
    let onChangeExercise: () -> Void
    let onToggleExpanded: () -> Void
    let onUseLast: () -> Void
    let onSelectRPE: () -> Void
    let onMarkComplete: () -> Void
    let onMarkSkipped: () -> Void
    let onMarkIncomplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            onToggleExpanded()
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.plain)
                }

                if let plannedMovementName, plannedMovementName != title {
                    Text("Planned: \(plannedMovementName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !isExpanded {
                    Text("Modality: \(modality.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Label(statusLabel, systemImage: statusIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)

                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let lastPerformanceSummary {
                Text("Last: \(lastPerformanceSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if showsDuplicateTravelWarning {
                Label("Travel substitute duplicated", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                Button("Change Exercise", action: onChangeExercise)
                    .buttonStyle(.bordered)
                Button("Use Last", action: onUseLast)
                    .buttonStyle(.bordered)
                    .disabled(!canUseLast)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Modality")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Modality", selection: $modality) {
                    ForEach(allowedModalities) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }

            HStack(spacing: 12) {
                sessionField(title: "Sets", text: $setsText, isDisabled: false, placeholder: "Sets")
                sessionField(title: modality == .bodyweight ? "Weight (N/A)" : "Weight", text: $weightText, isDisabled: modality == .bodyweight, placeholder: modality == .bodyweight ? "N/A" : "Weight")
                sessionField(title: "Actual Reps", text: $repsText, isDisabled: false, placeholder: "Reps")
            }

            HStack {
                Button {
                    onSelectRPE()
                } label: {
                    HStack(spacing: 6) {
                        Text("RPE")
                        Text(selectedRPE.map(String.init) ?? "Set")
                            .foregroundStyle(selectedRPE == nil ? .secondary : .primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Optional notes", text: $notesText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
            }

            HStack(spacing: 10) {
                Button("Complete", action: onMarkComplete)
                    .buttonStyle(.borderedProminent)
                Button("Skip", action: onMarkSkipped)
                    .buttonStyle(.bordered)
                Button("Incomplete", action: onMarkIncomplete)
                    .buttonStyle(.bordered)
            }
            .controlSize(.regular)
        }
    }

    private var statusLabel: String {
        switch status {
        case .notStarted:
            return "Not Started"
        case .completed:
            return "Completed"
        case .skipped:
            return "Skipped"
        case .incomplete:
            return "Incomplete"
        }
    }

    private var statusIcon: String {
        switch status {
        case .notStarted:
            return "circle"
        case .completed:
            return "checkmark.circle.fill"
        case .skipped:
            return "forward.circle.fill"
        case .incomplete:
            return "exclamationmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .notStarted:
            return .secondary
        case .completed:
            return .green
        case .skipped:
            return .orange
        case .incomplete:
            return .red
        }
    }

    private var summaryLine: String {
        if let currentRound {
            return "Round \(currentRound) • Planned \(plannedSets)x\(plannedReps)"
        }
        return "Planned \(plannedSets)x\(plannedReps)"
    }

    private func sessionField(title: String, text: Binding<String>, isDisabled: Bool, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.55 : 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        ActiveSessionView(activeSession: ActiveSession(
            plannedSessionId: "plan-1",
            blocks: [
                ActiveSessionBlock(
                    type: .alternating,
                    order: 0,
                    currentRound: 1,
                    roundsCompleted: 0,
                    items: [
                        ActiveSessionItem(
                            movementId: "bench-press",
                            effectiveMovementId: "bench-press",
                            selectedModality: .barbell,
                            plannedSets: 3,
                            plannedReps: 8,
                            status: .notStarted,
                            notes: nil
                        ),
                        ActiveSessionItem(
                            movementId: "barbell-row",
                            effectiveMovementId: "barbell-row",
                            selectedModality: .barbell,
                            plannedSets: 3,
                            plannedReps: 10,
                            status: .notStarted,
                            notes: nil
                        )
                    ]
                )
            ]
        ))
    }
    .modelContainer(for: [Movement.self, PlannedSession.self, ActiveSession.self], inMemory: true)
}
