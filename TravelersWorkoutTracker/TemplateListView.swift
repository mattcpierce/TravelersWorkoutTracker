// TemplateListView.swift
import SwiftData
import SwiftUI

struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]

    @State private var showingNewTemplateSheet = false
    @State private var searchText = ""
    @State private var saveErrorMessage: String?
    @State private var newlyCreatedTemplate: WorkoutTemplate?
    @State private var shouldNavigateToNewTemplate = false

    private var filteredTemplates: [WorkoutTemplate] {
        if searchText.isEmpty { return templates }
        return templates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var mostRecentDateByTemplateId: [String: Date] {
        var results: [String: Date] = [:]
        for session in sessions where results[session.templateId] == nil {
            results[session.templateId] = session.date
        }
        return results
    }

    private var mediumDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        List {
            if filteredTemplates.isEmpty {
                ContentUnavailableView(
                    "No Matching Templates",
                    systemImage: "magnifyingglass",
                    description: Text("Adjust search or create a new template.")
                )
            } else {
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                            Text(lastPerformedText(for: template))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteTemplates)
            }
        }
        .navigationTitle("Templates")
        .searchable(text: $searchText, prompt: "Search templates")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button("+ New Template") {
                    showingNewTemplateSheet = true
                }
            }
        }
        .sheet(isPresented: $showingNewTemplateSheet) {
            NewTemplateView { templateName in
                createTemplate(with: templateName)
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToNewTemplate) {
            if let template = newlyCreatedTemplate {
                TemplateDetailView(template: template, shouldShowAddMovementOnAppear: true)
            } else {
                Text("Template unavailable")
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

    private func createTemplate(with name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let template = WorkoutTemplate(name: trimmed)
        modelContext.insert(template)
        do {
            try modelContext.save()
            newlyCreatedTemplate = template
            shouldNavigateToNewTemplate = true
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTemplates[index])
        }
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func lastPerformedText(for template: WorkoutTemplate) -> String {
        guard let date = mostRecentDateByTemplateId[template.id] else { return "Never performed" }
        return "Last performed: \(mediumDateFormatter.string(from: date))"
    }
}
