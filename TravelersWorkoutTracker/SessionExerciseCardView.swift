// SessionExerciseCardView.swift
import SwiftUI

struct SessionExerciseCardView: View {
    @Environment(\.colorScheme) private var colorScheme

    let exerciseName: String
    let descriptionText: String?
    let lastTimeText: String?
    let isComplete: Bool
    let isPinned: Bool
    let canPinMore: Bool
    let isExpanded: Bool
    let hasHotelAlternative: Bool

    @Binding var useHotelVersion: Bool
    @Binding var setsText: String
    @Binding var repsText: String
    @Binding var weightText: String

    let onTogglePin: () -> Void
    let onToggleExpand: () -> Void
    let onUseLastTime: () -> Void
    let onComplete: () -> Void

    var body: some View {
        let cardBackground = Color(uiColor: isComplete ? .secondarySystemBackground : .systemBackground)
        let textOpacity: Double = isComplete ? 0.9 : 1

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exerciseName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .opacity(textOpacity)
                Spacer()

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.opacity)
                }
            }

            if let descriptionText,
               !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(descriptionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)

                    Button(isExpanded ? "Show Less" : "Show More") {
                        onToggleExpand()
                    }
                    .font(.caption)
                }
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }

            HStack {
                if let lastTimeText {
                    Text("Last time: \(lastTimeText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(textOpacity)
                }

                Spacer()

                Button {
                    onTogglePin()
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.borderless)
                .disabled(!isPinned && !canPinMore)

                if isComplete {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Incomplete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 70), spacing: 8),
                GridItem(.flexible(minimum: 70), spacing: 8),
                GridItem(.flexible(minimum: 70), spacing: 8)
            ], spacing: 8) {
                fieldColumn(title: "Sets", text: $setsText)
                fieldColumn(title: "Reps", text: $repsText)
                fieldColumn(title: "Weight", text: $weightText)
            }

            if hasHotelAlternative {
                Toggle("Use Hotel Version", isOn: $useHotelVersion)
                    .toggleStyle(.switch)
            } else {
                Text("Hotel version unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Use Last Time") {
                    onUseLastTime()
                }
                .buttonStyle(.bordered)
                .disabled(lastTimeText == nil)

                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardBackground)
        )
        .overlay(alignment: .leading) {
            if isComplete {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.green)
                    .frame(width: 4)
                    .padding(.vertical, 8)
            }
        }
        .shadow(
            color: colorScheme == .light ? Color.black.opacity(0.08) : Color.clear,
            radius: colorScheme == .light ? 3 : 0,
            x: 0,
            y: colorScheme == .light ? 1 : 0
        )
        .animation(.easeInOut(duration: 0.2), value: isComplete)
    }

    @ViewBuilder
    private func fieldColumn(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    SessionExerciseCardView(
        exerciseName: "Goblet Squat",
        descriptionText: "A squat holding a dumbbell at chest height. Promotes proper depth and posture with minimal equipment.",
        lastTimeText: "3x10 @ 40 @ RPE 8",
        isComplete: false,
        isPinned: false,
        canPinMore: true,
        isExpanded: false,
        hasHotelAlternative: true,
        useHotelVersion: .constant(false),
        setsText: .constant("3"),
        repsText: .constant("10"),
        weightText: .constant("40"),
        onTogglePin: {},
        onToggleExpand: {},
        onUseLastTime: {},
        onComplete: {}
    )
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
