// SegmentedRPEPicker.swift
import SwiftUI

struct SegmentedRPEPicker: View {
    @Binding var selectedRPE: Int?

    var body: some View {
        Picker("RPE", selection: $selectedRPE) {
            Text("-").tag(nil as Int?)
            ForEach(6...10, id: \.self) { value in
                Text("\(value)").tag(Optional(value))
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    SegmentedRPEPicker(selectedRPE: .constant(8))
        .padding()
}
