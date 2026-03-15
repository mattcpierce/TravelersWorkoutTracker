// MovementListView.swift
// Updated in v2: tab root now uses MovementListView with direct Movement query
import SwiftData
import SwiftUI

struct MovementListView: View {
    @Query(sort: \Movement.name) private var movements: [Movement]
    @State private var searchText = ""
    @State private var selectedScope: MovementLibraryScope = .all
    @State private var showingAddMovement = false

    private var filteredMovements: [Movement] {
        movements.filter { movement in
            let matchesSearch = searchText.isEmpty
                || movement.name.localizedCaseInsensitiveContains(searchText)
                || movement.category.localizedCaseInsensitiveContains(searchText)
                || movement.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })

            let matchesScope: Bool
            switch selectedScope {
            case .all:
                matchesScope = true
            case .builtIn:
                matchesScope = !movement.isCustom
            case .custom:
                matchesScope = movement.isCustom
            }

            return matchesSearch && matchesScope
        }
    }

    private var builtInMovements: [Movement] {
        filteredMovements.filter { !$0.isCustom }
    }

    private var customMovements: [Movement] {
        filteredMovements.filter(\.isCustom)
    }

    var body: some View {
        List {
            if filteredMovements.isEmpty {
                ContentUnavailableView {
                    Label("No Movements Yet", systemImage: "figure.strengthtraining.traditional")
                } description: {
                    Text("No movements are currently available. If this is unexpected, confirm MovementSeeder completed.")
                }
            } else {
                if !builtInMovements.isEmpty {
                    Section("Built-In") {
                        ForEach(builtInMovements) { movement in
                            movementRow(for: movement)
                        }
                    }
                }

                if !customMovements.isEmpty {
                    Section("Custom") {
                        ForEach(customMovements) { movement in
                            movementRow(for: movement)
                        }
                    }
                }
            }
        }
        .navigationTitle("Library")
        .searchable(text: $searchText, prompt: "Search movements")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddMovement = true
                } label: {
                    Label("Add Movement", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMovement) {
            MovementEditorView()
        }
        .safeAreaInset(edge: .top) {
            Picker("Movement Type", selection: $selectedScope) {
                ForEach(MovementLibraryScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(.bar)
        }
    }

    private func movementRow(for movement: Movement) -> some View {
        NavigationLink {
            ExerciseDetailView(movement: movement)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(movement.name)
                    .font(.headline)
                Text("\(movement.category) • \(movement.isCustom ? "Custom" : "Built-In")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(movement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

}

private enum MovementLibraryScope: String, CaseIterable, Identifiable {
    case all
    case builtIn
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .builtIn:
            return "Built-In"
        case .custom:
            return "Custom"
        }
    }
}

#Preview {
    MovementListView()
        .modelContainer(for: [Movement.self], inMemory: true)
}
