import SwiftUI

struct QuickRPEPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedRPE: Int?

    var body: some View {
        NavigationStack {
            List {
                Section("Choose RPE") {
                    Button("Clear") {
                        selectedRPE = nil
                        dismiss()
                    }

                    ForEach(6...10, id: \.self) { value in
                        Button {
                            selectedRPE = value
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(value)")
                                Spacer()
                                if selectedRPE == value {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("RPE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    QuickRPEPickerSheet(selectedRPE: .constant(8))
}
