// NewTemplateView.swift
import SwiftUI

struct NewTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var templateName: String = ""

    var onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Template Name", text: $templateName)
            }
            .navigationTitle("New Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(templateName)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NewTemplateView { _ in }
}
