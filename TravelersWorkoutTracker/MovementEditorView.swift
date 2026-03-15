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
    @State private var tagsText: String
    @State private var hotelAlternativeMovementId: String?
    @State private var selectedModalities: Set<EquipmentType>
    @State private var searchText = ""
    @State private var saveErrorMessage: String?

    init(movement: Movement? = nil) {
        self.movement = movement
        self.isEditing = movement != nil
        _name = State(initialValue: movement?.name ?? "")
        _descriptionText = State(initialValue: movement?.description ?? "")
        _category = State(initialValue: movement?.category ?? "Custom")
        _tagsText = State(initialValue: movement?.tags.joined(separator: ", ") ?? "")
        _hotelAlternativeMovementId = State(initialValue: movement?.hotelAlternativeMovementId)
        _selectedModalities = State(initialValue: Set(movement?.allowedModalities ?? [.bodyweight]))
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
                    TextField("Comma-separated tags", text: $tagsText, axis: .vertical)
                        .lineLimit(2...4)
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
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

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

    private func customMovementId(from name: String) -> String {
        let slug = name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "custom-\(slug)-\(UUID().uuidString.prefix(8))"
    }
}

#Preview {
    MovementEditorView()
        .modelContainer(for: [Movement.self], inMemory: true)
}
