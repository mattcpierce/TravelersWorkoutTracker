// SessionMonthCalendarView.swift
import SwiftUI

struct SessionMonthCalendarView: View {
    let displayedMonth: Date
    let markedDays: Set<Int>
    let selectedDay: Int?
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onSelectDay: (Int?) -> Void

    private let calendar = Calendar.current

    private var startOfMonth: Date {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: components) ?? displayedMonth
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: startOfMonth)?.count ?? 0
    }

    private var leadingEmptyCells: Int {
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        var offset = firstWeekday - calendar.firstWeekday
        if offset < 0 { offset += 7 }
        return offset
    }

    private var dayCells: [Int?] {
        var cells = Array<Int?>(repeating: nil, count: leadingEmptyCells)
        cells.append(contentsOf: Array(1...daysInMonth).map { Optional($0) })

        while cells.count % 7 != 0 {
            cells.append(nil)
        }

        return cells
    }

    private var monthLabel: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayHeaders: [String] {
        let headers = calendar.shortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(headers[shift...] + headers[..<shift])
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                Text(monthLabel)
                    .font(.headline)

                Spacer()

                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(dayCells.indices, id: \.self) { index in
                    if let day = dayCells[index] {
                        Button {
                            if selectedDay == day {
                                onSelectDay(nil)
                            } else {
                                onSelectDay(day)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text("\(day)")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)

                                if markedDays.contains(day) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                } else {
                                    Color.clear
                                        .frame(height: 10)
                                }
                            }
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedDay == day ? Color.accentColor.opacity(0.2) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
