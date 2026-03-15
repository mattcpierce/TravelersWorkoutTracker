// ExerciseListView.swift
import SwiftData
import SwiftUI

struct ExerciseListView: View {
    @Query(sort: [SortDescriptor(\Movement.name)]) private var movements: [Movement]
    @Query(sort: [SortDescriptor(\WorkoutTemplate.name)]) private var templates: [WorkoutTemplate]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]

    @AppStorage("exerciseFilter_selectedEquipment") private var persistedEquipmentJSON = "[]"
    @AppStorage("exerciseFilter_hotelOnly") private var persistedHotelOnly = false

    @State private var filterState = ExerciseFilterState()
    @State private var hasLoadedFilters = false
    @State private var searchText = ""
    @State private var showingAddMovement = false
    @State private var showingFilters = false

    private let hotelCompatible: Set<EquipmentType> = [
        .dumbbells,
        .bodyweight,
        .treadmill,
        .resistanceBand
    ]

    private var movementEquipmentLookup: [String: Set<EquipmentType>] {
        var lookup: [String: Set<EquipmentType>] = [:]

        for template in templates {
            for entry in template.orderedMovements {
                lookup[entry.movementId, default: []].insert(entry.defaultEquipment)
            }
        }

        for session in sessions {
            for entry in session.sessionExercises {
                lookup[entry.movementId, default: []].insert(entry.equipment)
            }
        }

        return lookup
    }

    private var filteredMovements: [Movement] {
        movements.filter { movement in
            let movementNameMatches = searchText.isEmpty || movement.name.localizedCaseInsensitiveContains(searchText)
            guard movementNameMatches else { return false }

            if filterState.hotelOnly {
                guard let equipmentSet = movementEquipmentLookup[movement.id],
                      !equipmentSet.isDisjoint(with: hotelCompatible)
                else {
                    return false
                }
            }

            if !filterState.selectedEquipment.isEmpty {
                guard let equipmentSet = movementEquipmentLookup[movement.id],
                      !equipmentSet.isDisjoint(with: filterState.selectedEquipment)
                else {
                    return false
                }
            }

            return true
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredMovements) { movement in
                NavigationLink {
                    ExerciseDetailView(movement: movement)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(movement.name)
                            .font(.headline)
                        Text(movement.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .navigationTitle("Movements")
            .searchable(text: $searchText, prompt: "Search movements")
            .onAppear(perform: loadPersistedFiltersIfNeeded)
            .onChange(of: filterState) { _, newState in
                persistedEquipmentJSON = ExerciseFilterState.encodeEquipment(newState.selectedEquipment)
                persistedHotelOnly = newState.hotelOnly
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingFilters = true
                    } label: {
                        if filterState.activeFilterCount > 0 {
                            Label("Filters: \(filterState.activeFilterCount)", systemImage: "line.3.horizontal.decrease.circle.fill")
                        } else {
                            Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMovement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMovement) {
                AddExerciseView()
            }
            .sheet(isPresented: $showingFilters) {
                ExerciseFiltersSheetView(
                    filterState: $filterState,
                    equipmentOptions: EquipmentType.allCases
                )
            }
        }
    }

    private func loadPersistedFiltersIfNeeded() {
        guard !hasLoadedFilters else { return }
        filterState.selectedEquipment = ExerciseFilterState.decodeEquipment(from: persistedEquipmentJSON)
        filterState.hotelOnly = persistedHotelOnly
        hasLoadedFilters = true
    }
}

#Preview {
    ExerciseListView()
        .modelContainer(for: [Movement.self, WorkoutTemplate.self, WorkoutSession.self, SessionExercise.self], inMemory: true)
}
