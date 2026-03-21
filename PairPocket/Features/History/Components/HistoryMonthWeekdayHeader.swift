import SwiftUI

struct HistoryMonthWeekdayHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(HistoryCalendar.shortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
