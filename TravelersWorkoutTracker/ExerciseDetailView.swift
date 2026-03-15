// ExerciseDetailView.swift
import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    @Query(sort: [SortDescriptor(\Movement.name)]) private var allMovements: [Movement]
    @State private var showingEditMovement = false

    let movement: Movement

    private var hotelAlternativeName: String? {
        guard let hotelAlternativeMovementId = movement.hotelAlternativeMovementId else { return nil }
        return allMovements.first(where: { $0.id == hotelAlternativeMovementId })?.name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(movement.name)
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 6) {
                    Text(movement.category)
                        .font(.headline)
                    Text(movement.isCustom ? "Custom Movement" : "Built-In Movement")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !movement.tags.isEmpty {
                        Text(movement.tags.joined(separator: " • "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Description")
                    .font(.headline)
                Text(movement.description)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Allowed Modalities")
                        .font(.headline)
                    Text(movement.allowedModalities.map(\.label).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Hotel Alternative")
                        .font(.headline)
                    Text(hotelAlternativeName ?? "No automatic travel substitute set")
                        .foregroundStyle(.secondary)
                }

                NavigationLink("History") {
                    ExerciseSessionHistoryView(movement: movement)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(movement.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if movement.isCustom {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        showingEditMovement = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditMovement) {
            MovementEditorView(movement: movement)
        }
    }
}
