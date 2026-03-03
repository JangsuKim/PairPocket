import SwiftUI

struct HistoryView: View {
    @State private var displayedMonth: Date
    @State private var selectedDate: Date
    @State private var selectedPocketFilter: String? = nil

    private let calendar = Calendar.current
    private let weekLabels = ["日", "月", "火", "水", "木", "金", "土"]
    private let pocketFilters: [String?] = [nil, "生活費", "旅行", "家賃"]

    init() {
        let now = Date()
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        _displayedMonth = State(initialValue: monthStart)
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: now))
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var monthlyExpenses: [HistoryExpense] {
        [
            .init(date: dateInDisplayedMonth(day: 2), pocketName: "生活費", pocketColor: .green, category: "食費", memo: "スーパー", payer: "A", amount: 3_280),
            .init(date: dateInDisplayedMonth(day: 2), pocketName: "旅行", pocketColor: .orange, category: "カフェ", memo: "休憩", payer: "B", amount: 980),
            .init(date: dateInDisplayedMonth(day: 5), pocketName: "生活費", pocketColor: .green, category: "日用品", memo: "ドラッグストア", payer: "B", amount: 2_150),
            .init(date: dateInDisplayedMonth(day: 9), pocketName: "旅行", pocketColor: .orange, category: "交通", memo: "電車", payer: "A", amount: 1_120),
            .init(date: dateInDisplayedMonth(day: 12), pocketName: "生活費", pocketColor: .green, category: "外食", memo: "ランチ", payer: "A", amount: 1_600),
            .init(date: dateInDisplayedMonth(day: 12), pocketName: "生活費", pocketColor: .green, category: "食費", memo: "コンビニ", payer: "B", amount: 740),
            .init(date: dateInDisplayedMonth(day: 18), pocketName: "旅行", pocketColor: .orange, category: "ホテル", memo: "予約", payer: "A", amount: 8_200),
            .init(date: dateInDisplayedMonth(day: 20), pocketName: "家賃", pocketColor: .purple, category: "住居", memo: "月額", payer: "A", amount: 78_000),
            .init(date: dateInDisplayedMonth(day: 24), pocketName: "生活費", pocketColor: .green, category: "食費", memo: "まとめ買い", payer: "A", amount: 5_430),
            .init(date: dateInDisplayedMonth(day: 27), pocketName: "旅行", pocketColor: .orange, category: "観光", memo: "入場料", payer: "B", amount: 2_400),
        ]
    }

    private var filteredExpenses: [HistoryExpense] {
        guard let selectedPocketFilter else {
            return monthlyExpenses
        }
        return monthlyExpenses.filter { $0.pocketName == selectedPocketFilter }
    }

    private var dailyTotals: [Date: Int] {
        Dictionary(grouping: filteredExpenses, by: { calendar.startOfDay(for: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    private var selectedDayExpenses: [HistoryExpense] {
        filteredExpenses.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var monthTotalAmount: Int {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }

    private var monthTransactionCount: Int {
        filteredExpenses.count
    }

    private var dayCells: [CalendarDayCell] {
        let firstWeekday = calendar.component(.weekday, from: displayedMonth)
        let leadingBlankCount = firstWeekday - 1
        let dayCount = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 0

        var cells: [CalendarDayCell] = Array(repeating: .empty, count: leadingBlankCount)
        cells.append(contentsOf: (1...dayCount).map { .day($0) })

        return cells
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                monthHeader

                Text("合計 \(formatYen(monthTotalAmount)) / \(monthTransactionCount)件")
                    .font(.subheadline.weight(.medium))

                pocketFilterChips

                calendarSection

                selectedDayListSection
            }
            .padding()
        }
        .navigationTitle("履歴")
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
        }
    }

    private var pocketFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(pocketFilters, id: \.self) { filter in
                    let isSelected = selectedPocketFilter == filter
                    Button {
                        selectedPocketFilter = filter
                    } label: {
                        Text(filter ?? "すべて")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(isSelected ? Color.accentColor : .primary)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var calendarSection: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, cell in
                    switch cell {
                    case .empty:
                        Color.clear
                            .frame(height: 54)
                    case .day(let day):
                        let date = dateInDisplayedMonth(day: day)
                        let total = dailyTotals[calendar.startOfDay(for: date)] ?? 0
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

                        Button {
                            selectedDate = calendar.startOfDay(for: date)
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(day)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(total > 0 ? formatYen(total) : "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var selectedDayListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDateTitle)
                .font(.headline)

            if selectedDayExpenses.isEmpty {
                Text("この日の支出はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(selectedDayExpenses) { expense in
                    expenseRow(expense)
                }
            }
        }
    }

    private var selectedDateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d の支出"
        return formatter.string(from: selectedDate)
    }

    private func expenseRow(_ expense: HistoryExpense) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(expense.pocketColor)
                .frame(width: 4, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(expense.category) ・ \(expense.memo)")
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text(expense.payer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(formatYen(expense.amount))
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func changeMonth(by offset: Int) {
        guard let nextMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        displayedMonth = startOfMonth(nextMonth)
        selectedDate = displayedMonth
    }

    private func dateInDisplayedMonth(day: Int) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        return calendar.date(from: comps) ?? displayedMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

private struct HistoryExpense: Identifiable {
    let id = UUID()
    let date: Date
    let pocketName: String
    let pocketColor: Color
    let category: String
    let memo: String
    let payer: String
    let amount: Int
}

private enum CalendarDayCell {
    case empty
    case day(Int)
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
