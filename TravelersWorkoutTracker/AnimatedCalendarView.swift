// AnimatedCalendarView.swift
import SwiftUI

struct AnimatedCalendarView: View {
    let displayedMonth: Date
    let selectedDay: Int?
    let workoutCountByDay: [Int: Int]
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onSelectDay: (Int?) -> Void

    private let calendar = Calendar.current

    private var monthLabel: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var startOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: components) ?? displayedMonth
    }

    private var dayCells: [Int?] {
        let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        var leading = firstWeekday - calendar.firstWeekday
        if leading < 0 { leading += 7 }

        var cells = Array<Int?>(repeating: nil, count: leading)
        cells.append(contentsOf: (1...daysInMonth).map { Optional($0) })

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    onPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(monthLabel)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    onNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 0), spacing: 6), count: 7), spacing: 8) {
                ForEach(weekdayHeaders, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button {
                            onSelectDay(selectedDay == day ? nil : day)
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(day)")
                                    .font(.subheadline)
                                    .foregroundStyle(selectedDay == day ? .white : .primary)
                                    .frame(maxWidth: .infinity)

                                if let count = workoutCountByDay[day], count > 0 {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(selectedDay == day ? .white : .yellow)
                                } else {
                                    Color.clear
                                        .frame(height: 8)
                                }
                            }
                            .frame(minHeight: 40)
                            .padding(.vertical, 2)
                            .background(
                                Circle()
                                    .fill(selectedDay == day ? Color.accentColor : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(minHeight: 40)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AnimatedCalendarView(
        displayedMonth: .now,
        selectedDay: 3,
        workoutCountByDay: [1: 1, 3: 2, 12: 1],
        onPreviousMonth: {},
        onNextMonth: {},
        onSelectDay: { _ in }
    )
    .padding()
}
