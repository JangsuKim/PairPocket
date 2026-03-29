import SwiftUI

struct HistoryMonthGrid: View {
    let displayedMonthStart: Date
    let datesWithExpenses: Set<Date>
    let accentColor: Color
    @Binding var selectedDate: Date

    private var cells: [MonthCell] {
        HistoryCalendar.monthCells(for: displayedMonthStart)
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(cells) { cell in
                if let date = cell.date {
                    let isSelected = HistoryCalendar.isSameDay(date, selectedDate)
                    let hasExpense = datesWithExpenses.contains(HistoryCalendar.dayStart(for: date))

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(HistoryCalendar.dayNumber(for: date))")
                                .font(.caption)
                                .foregroundStyle(isSelected ? Color.white : Color.primary)

                            Circle()
                                .fill(hasExpense ? (isSelected ? Color.white : accentColor) : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isSelected ? accentColor : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
