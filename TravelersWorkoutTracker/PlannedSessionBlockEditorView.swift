import SwiftUI

struct PlannedSessionBlockEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let movements: [Movement]
    let initialBlock: SessionBlock?
    let onSave: (SessionBlock) -> Void

    @State private var draft: BlockDraft
    @State private var pickerTargetItemId: String?

    init(
        movements: [Movement],
        initialBlock: SessionBlock?,
        onSave: @escaping (SessionBlock) -> Void
    ) {
        self.movements = movements
        self.initialBlock = initialBlock
        self.onSave = onSave
        _draft = State(initialValue: BlockDraft(block: initialBlock))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Block Type") {
                    Picker("Type", selection: $draft.type) {
                        ForEach(SessionBlockType.allCases) { type in
                            Text(type == .single ? "Single Exercise" : "Alternating Block")
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: draft.type) { _, newType in
                        draft.normalize(for: newType)
                    }
                }

                Section("Exercises") {
                    ForEach($draft.items) { $item in
                        VStack(alignment: .leading, spacing: 10) {
                            Button {
                                pickerTargetItemId = item.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(movementName(for: item.movementId) ?? "Choose Movement")
                                            .foregroundStyle(item.movementId.isEmpty ? .secondary : .primary)
                                        if let movement = movement(for: item.movementId) {
                                            Text(movement.category)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            HStack(spacing: 12) {
                                numericField(title: "Sets", value: $item.plannedSets)
                                numericField(title: "Reps", value: $item.plannedReps)
                            }

                            TextField("Notes", text: Binding(
                                get: { item.notes ?? "" },
                                set: { item.notes = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                            ), axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: removeItems)

                    if draft.type == .alternating && draft.items.count < 3 {
                        Button("Add Third Exercise") {
                            draft.addItem()
                        }
                    }
                }
            }
            .navigationTitle(initialBlock == nil ? "Add Block" : "Edit Block")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft.makeBlock(existing: initialBlock))
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
            .sheet(isPresented: Binding(
                get: { pickerTargetItemId != nil },
                set: { if !$0 { pickerTargetItemId = nil } }
            )) {
                PlannedSessionMovementPickerView(movements: movements) { movement in
                    if let itemId = pickerTargetItemId {
                        draft.setMovement(movement.id, forItemID: itemId)
                    }
                    pickerTargetItemId = nil
                }
            }
        }
    }

    private func movementName(for movementId: String) -> String? {
        movements.first(where: { $0.id == movementId })?.name
    }

    private func movement(for movementId: String) -> Movement? {
        movements.first(where: { $0.id == movementId })
    }

    @ViewBuilder
    private func numericField(title: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: Binding(
                get: { value.wrappedValue == 0 ? "" : String(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) ?? 0 }
            ))
            .textFieldStyle(.roundedBorder)
            .keyboardType(.numberPad)
        }
    }

    private func removeItems(at offsets: IndexSet) {
        draft.items.remove(atOffsets: offsets)
        draft.normalize(for: draft.type)
    }
}

private struct BlockDraft {
    var type: SessionBlockType
    var items: [BlockDraftItem]

    nonisolated init(block: SessionBlock?) {
        if let block {
            type = block.type
            items = block.items
                .sorted { $0.blockPosition < $1.blockPosition }
                .map(BlockDraftItem.init)
        } else {
            type = .single
            items = [BlockDraftItem()]
        }
        normalize(for: type)
    }

    nonisolated var isValid: Bool {
        let validCount = type == .single ? items.count == 1 : (2...3).contains(items.count)
        let allMovementsPicked = items.allSatisfy { !$0.movementId.isEmpty }
        let allValuesValid = items.allSatisfy { $0.plannedSets > 0 && $0.plannedReps > 0 }
        return validCount && allMovementsPicked && allValuesValid
    }

    nonisolated mutating func normalize(for type: SessionBlockType) {
        self.type = type

        switch type {
        case .single:
            if items.isEmpty {
                items = [BlockDraftItem()]
            } else {
                items = [items[0]]
            }
        case .alternating:
            if items.count < 2 {
                while items.count < 2 {
                    items.append(BlockDraftItem())
                }
            } else if items.count > 3 {
                items = Array(items.prefix(3))
            }
        }

        for index in items.indices {
            items[index].blockPosition = index
        }
    }

    nonisolated mutating func addItem() {
        guard items.count < 3 else { return }
        items.append(BlockDraftItem(blockPosition: items.count))
    }

    nonisolated mutating func setMovement(_ movementId: String, forItemID itemID: String) {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[index].movementId = movementId
    }

    nonisolated func makeBlock(existing: SessionBlock?) -> SessionBlock {
        SessionBlock(
            id: existing?.id ?? UUID().uuidString,
            type: type,
            order: existing?.order ?? 0,
            items: items.enumerated().map { index, item in
                SessionBlockItem(
                    id: item.id,
                    movementId: item.movementId,
                    plannedSets: item.plannedSets,
                    plannedReps: item.plannedReps,
                    notes: item.notes,
                    blockPosition: index
                )
            }
        )
    }
}

private struct BlockDraftItem: Identifiable {
    var id: String = UUID().uuidString
    var movementId: String = ""
    var plannedSets: Int = 3
    var plannedReps: Int = 10
    var notes: String?
    var blockPosition: Int = 0

    nonisolated init() {}

    nonisolated init(blockPosition: Int) {
        self.blockPosition = blockPosition
    }

    nonisolated init(item: SessionBlockItem) {
        id = item.id
        movementId = item.movementId
        plannedSets = item.plannedSets
        plannedReps = item.plannedReps
        notes = item.notes
        blockPosition = item.blockPosition
    }
}

private struct PlannedSessionMovementPickerView: View {
    @Environment(\.dismiss) private var dismiss

    let movements: [Movement]
    let onSelect: (Movement) -> Void

    @State private var searchText = ""

    private var filteredMovements: [Movement] {
        if searchText.isEmpty { return movements }
        return movements.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredMovements) { movement in
                Button {
                    onSelect(movement)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movement.name)
                            .foregroundStyle(.primary)
                        Text(movement.category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose Movement")
            .searchable(text: $searchText, prompt: "Search movements")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PlannedSessionBlockEditorView(
        movements: [],
        initialBlock: nil,
        onSave: { _ in }
    )
}
