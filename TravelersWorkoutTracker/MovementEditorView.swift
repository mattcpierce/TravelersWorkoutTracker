import SwiftData
import SwiftUI

struct MovementEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Movement.name)]) private var allMovements: [Movement]

    private let movement: Movement?
    private let isEditing: Bool

    @State private var name: String
    @State private var descriptionText: String
    @State private var category: String
    @State private var selectedTags: [String]
    @State private var hotelAlternativeMovementId: String?
    @State private var selectedModalities: Set<EquipmentType>
    @State private var searchText = ""
    @State private var saveErrorMessage: String?
    @State private var customTagText = ""

    init(movement: Movement? = nil) {
        self.movement = movement
        self.isEditing = movement != nil
        _name = State(initialValue: movement?.name ?? "")
        _descriptionText = State(initialValue: movement?.description ?? "")
        _category = State(initialValue: movement?.category ?? "Custom")
        _selectedTags = State(initialValue: movement?.tags ?? [])
        _hotelAlternativeMovementId = State(initialValue: movement?.hotelAlternativeMovementId)
        _selectedModalities = State(initialValue: Set(movement?.allowedModalities ?? [.bodyweight]))
    }

    private var allKnownTags: [String] {
        let tags = Set(allMovements.flatMap(\.tags))
        return tags.sorted()
    }

    private var suggestedTags: [String] {
        let categorySuggestions = Self.suggestedTagsByCategory[category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] ?? []
        let pool = Set(categorySuggestions).union(allKnownTags)
        return pool.sorted()
    }

    private var availableHotelAlternatives: [Movement] {
        let candidates = allMovements.filter { candidate in
            guard let movement else { return true }
            return candidate.id != movement.id
        }

        guard !searchText.isEmpty else { return candidates }
        return candidates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedModalities.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Movement") {
                    TextField("Name", text: $name)
                    TextField("Description", text: $descriptionText, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Category", text: $category)
                }

                Section("Tags") {
                    if selectedTags.isEmpty {
                        Text("Choose tags that describe the movement so it is easier to search later.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        tagGrid(tags: selectedTags, selected: true)
                    }

                    HStack {
                        TextField("Add custom tag", text: $customTagText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            addCustomTag()
                        }
                        .disabled(customTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if !suggestedTags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Tags")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                            tagGrid(tags: suggestedTags, selected: false)
                        }
                    }
                }

                Section("Allowed Modalities") {
                    ForEach(EquipmentType.allCases) { modality in
                        Toggle(isOn: binding(for: modality)) {
                            Text(modality.label)
                        }
                    }
                }

                Section("Hotel Alternative") {
                    TextField("Search movements", text: $searchText)

                    Button("No automatic substitute") {
                        hotelAlternativeMovementId = nil
                    }
                    .foregroundStyle(.primary)

                    ForEach(availableHotelAlternatives) { candidate in
                        Button {
                            hotelAlternativeMovementId = candidate.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(candidate.name)
                                    Text(candidate.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if hotelAlternativeMovementId == candidate.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Movement" : "Add Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveMovement()
                    }
                    .disabled(!canSave)
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
    }

    private func binding(for modality: EquipmentType) -> Binding<Bool> {
        Binding(
            get: { selectedModalities.contains(modality) },
            set: { isSelected in
                if isSelected {
                    selectedModalities.insert(modality)
                } else {
                    selectedModalities.remove(modality)
                }
            }
        )
    }

    private func saveMovement() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = selectedTags

        let modalities = EquipmentType.allCases.filter { selectedModalities.contains($0) }

        if let movement {
            movement.name = trimmedName
            movement.description = trimmedDescription
            movement.category = trimmedCategory
            movement.tags = tags
            movement.hotelAlternativeMovementId = hotelAlternativeMovementId
            movement.allowedModalities = modalities
            movement.isCustom = true
        } else {
            let customMovement = Movement(
                id: customMovementId(from: trimmedName),
                name: trimmedName,
                description: trimmedDescription,
                category: trimmedCategory,
                tags: tags,
                hotelAlternativeMovementId: hotelAlternativeMovementId,
                allowedModalities: modalities,
                isCustom: true
            )
            modelContext.insert(customMovement)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func slugified(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func customMovementId(from name: String) -> String {
        "custom-\(slugified(name))-\(UUID().uuidString.prefix(8))"
    }

    private func addCustomTag() {
        let normalizedTag = slugified(customTagText)

        guard !normalizedTag.isEmpty else { return }
        toggleTag(normalizedTag)
        customTagText = ""
    }

    private func toggleTag(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
            selectedTags.sort()
        }
    }

    @ViewBuilder
    private func tagGrid(tags: [String], selected: Bool) -> some View {
        let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                let isSelected = selectedTags.contains(tag)
                Button {
                    toggleTag(tag)
                } label: {
                    HStack(spacing: 6) {
                        Text(tag)
                            .font(.footnote.weight(.medium))
                        if isSelected {
                            Image(systemName: selected ? "xmark.circle.fill" : "checkmark.circle.fill")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected ? Color.accentColor.opacity(0.16) : Color(.secondarySystemFill),
                        in: Capsule(style: .continuous)
                    )
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private static let suggestedTagsByCategory: [String: [String]] = [
        "squat": ["quads", "glutes", "compound", "unilateral", "hotel-friendly", "isolation"],
        "hinge": ["hamstrings", "glutes", "posterior-chain", "compound", "bodyweight", "lower-back"],
        "horizontal push": ["chest", "triceps", "compound", "upper-chest", "isolation", "hotel-friendly"],
        "vertical push": ["shoulders", "triceps", "compound", "upper-chest", "hotel-friendly"],
        "horizontal pull": ["back", "lats", "upper-back", "compound", "unilateral", "hotel-friendly"],
        "vertical pull": ["lats", "back", "compound", "biceps", "bodyweight", "regression"],
        "shoulders": ["delts", "rear-delts", "front-delts", "traps", "isolation", "hotel-friendly"],
        "arms": ["biceps", "triceps", "brachialis", "compound", "isolation", "hotel-friendly"],
        "core": ["core", "abs", "obliques", "stability", "anti-rotation", "anti-extension", "hotel-friendly"],
        "carry / conditioning": ["conditioning", "grip", "full-body", "unilateral", "calves", "hotel-friendly"],
        "custom": ["hotel-friendly", "compound", "isolation", "unilateral", "bodyweight"]
    ]
}

#Preview {
    MovementEditorView()
        .modelContainer(for: [Movement.self], inMemory: true)
}
