// SessionStartView.swift
import SwiftData
import SwiftUI

struct SessionStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutTemplate.name)]) private var templates: [WorkoutTemplate]

    @State private var selectedSession: WorkoutSession?
    @State private var navigateToSession = false
    @State private var saveErrorMessage: String?

    var body: some View {
        List {
            if templates.isEmpty {
                ContentUnavailableView(
                    "No Templates Available",
                    systemImage: "figure.run",
                    description: Text("Create a template first, then come back here to start a session.")
                )
            } else {
                ForEach(templates) { template in
                    Button {
                        startSession(from: template)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                            Text("\(template.orderedMovements.count) movements")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Start Session")
        .navigationDestination(isPresented: $navigateToSession) {
            if let selectedSession {
                SessionView(session: selectedSession)
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

    private func startSession(from template: WorkoutTemplate) {
        let seedEntries = template.orderedMovements.map { entry in
            SessionExercise(movementId: entry.movementId, equipment: entry.defaultEquipment)
        }

        let session = WorkoutSession(
            date: .now,
            templateId: template.id,
            sessionExercises: seedEntries
        )

        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
            return
        }

        selectedSession = session
        navigateToSession = true
    }
}
