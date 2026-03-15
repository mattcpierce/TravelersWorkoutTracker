import SwiftData
import SwiftUI

struct PlannedSessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]

    @Bindable var plannedSession: PlannedSession
    @State private var saveErrorMessage: String?
    @State private var showingBlockEditor = false
    @State private var editingBlockIndex: Int?

    private var orderedBlocks: [SessionBlock] {
        plannedSession.blocks.sorted { $0.order < $1.order }
    }

    private var movementLookup: [String: Movement] {
        Dictionary(uniqueKeysWithValues: movements.map { ($0.id, $0) })
    }

    var body: some View {
        List {
            Section("Session") {
                TextField("Session Name", text: $plannedSession.name)
                    .textInputAutocapitalization(.words)
                    .onSubmit(saveChanges)

                if let lastPerformedDate = plannedSession.lastPerformedDate {
                    LabeledContent("Last Performed") {
                        Text(lastPerformedDate.formatted(date: .abbreviated, time: .omitted))
                    }
                } else {
                    LabeledContent("Last Performed") {
                        Text("Never")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                if orderedBlocks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No blocks yet")
                            .font(.headline)
                        Text("Add a single-exercise block or an alternating block to build this session.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                } else {
                    ForEach(Array(orderedBlocks.enumerated()), id: \.element.id) { index, block in
                        Button {
                            editingBlockIndex = index
                            showingBlockEditor = true
                        } label: {
                            PlannedSessionBlockCard(
                                block: block,
                                movementLookup: movementLookup
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteBlocks)
                    .onMove(perform: moveBlocks)
                }

                Button("Add Block") {
                    editingBlockIndex = nil
                    showingBlockEditor = true
                }
            } header: {
                Text("Blocks")
            } footer: {
                Text("Single blocks contain one movement. Alternating blocks contain two or three movements that rotate by round.")
            }
        }
        .navigationTitle(plannedSession.name)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingBlockEditor) {
            PlannedSessionBlockEditorView(
                movements: movements,
                initialBlock: editingBlockIndex.flatMap { orderedBlocks[safe: $0] },
                onSave: { savedBlock in
                    upsertBlock(savedBlock, at: editingBlockIndex)
                }
            )
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage ?? "Please try again.")
        }
        .onDisappear(perform: saveChanges)
    }

    private func upsertBlock(_ block: SessionBlock, at orderedIndex: Int?) {
        var blocks = orderedBlocks
        var normalized = block

        if let orderedIndex, blocks.indices.contains(orderedIndex) {
            normalized.order = blocks[orderedIndex].order
            blocks[orderedIndex] = normalized
        } else {
            normalized.order = blocks.count
            blocks.append(normalized)
        }

        plannedSession.blocks = blocks.enumerated().map { index, block in
            var reordered = block
            reordered.order = index
            reordered.items = block.items.enumerated().map { itemIndex, item in
                var updatedItem = item
                updatedItem.blockPosition = itemIndex
                return updatedItem
            }
            return reordered
        }

        saveChanges()
    }

    private func deleteBlocks(at offsets: IndexSet) {
        var blocks = orderedBlocks
        blocks.remove(atOffsets: offsets)
        plannedSession.blocks = blocks.enumerated().map { index, block in
            var updatedBlock = block
            updatedBlock.order = index
            return updatedBlock
        }
        saveChanges()
    }

    private func moveBlocks(from source: IndexSet, to destination: Int) {
        var blocks = orderedBlocks
        blocks.move(fromOffsets: source, toOffset: destination)
        plannedSession.blocks = blocks.enumerated().map { index, block in
            var updatedBlock = block
            updatedBlock.order = index
            return updatedBlock
        }
        saveChanges()
    }

    private func saveChanges() {
        if plannedSession.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            plannedSession.name = "Untitled Session"
        }

        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }
}

private struct PlannedSessionBlockCard: View {
    let block: SessionBlock
    let movementLookup: [String: Movement]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(block.type == .single ? "Single Exercise Block" : "Alternating Block")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("Block \(block.order + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(block.items.sorted { $0.blockPosition < $1.blockPosition }) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(movementLookup[item.movementId]?.name ?? "Unknown Movement")
                        .foregroundStyle(.primary)
                    Text("\(item.plannedSets) sets x \(item.plannedReps) reps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

#Preview {
    NavigationStack {
        PlannedSessionDetailView(plannedSession: PlannedSession(name: "Upper A"))
    }
    .modelContainer(for: [PlannedSession.self, Movement.self], inMemory: true)
}
