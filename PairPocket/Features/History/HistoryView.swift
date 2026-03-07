import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ExpenseRecord.date, order: .reverse) private var expenses: [ExpenseRecord]
    @Query(sort: \PocketRecord.createdAt, order: .forward) private var pocketRecords: [PocketRecord]
    @Query private var deletedPocketRecords: [DeletedPocketRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(PocketStore.self) private var pocketStore

    @State private var selectedFilter: PocketFilter = .total
    @State private var selectedMode: ViewMode = .list
    @State private var displayedMonthStart: Date = HistoryCalendar.monthStart(for: Date())
    @State private var selectedDate: Date = HistoryCalendar.dayStart(for: Date())

    var body: some View {
        VStack(spacing: 8) {
            pocketFilterTabs
            modeSwitcher

            if selectedMode == .calendar {
                calendarModeContent
            } else {
                if filteredExpenses.isEmpty {
                    emptyState
                } else {
                    expenseTable(expenses: filteredExpenses)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .navigationTitle("履歴")
        .task {
            try? pocketStore.loadIfNeeded(from: modelContext)
        }
    }

    private var filteredExpenses: [ExpenseRecord] {
        switch selectedFilter {
        case .total:
            return expenses
        case let .pocket(id):
            return expenses.filter { $0.pocketId == id }
        }
    }

    private var deletedPocketIDs: Set<UUID> {
        Set(deletedPocketRecords.map(\.pocketId))
    }

    private var pocketOptions: [PocketOption] {
        pocketRecords
            .filter { deletedPocketIDs.contains($0.id) == false }
            .map(\.pocket)
            .map {
            PocketOption(id: $0.id, name: $0.name)
        }
    }

    private var calendarDatesWithExpenses: Set<Date> {
        Set(filteredExpenses.map { HistoryCalendar.dayStart(for: $0.date) })
    }

    private var selectedDateExpenses: [ExpenseRecord] {
        filteredExpenses.filter { HistoryCalendar.isSameDay($0.date, selectedDate) }
    }

    private var pocketFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "全体", isSelected: selectedFilter == .total) {
                    selectedFilter = .total
                }

                ForEach(pocketOptions) { option in
                    filterChip(title: option.name, isSelected: selectedFilter == .pocket(option.id)) {
                        selectedFilter = .pocket(option.id)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.primary : Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var modeSwitcher: some View {
        Picker("表示", selection: $selectedMode) {
            Text("カレンダー").tag(ViewMode.calendar)
            Text("リスト").tag(ViewMode.list)
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack {
            Spacer(minLength: 36)
            Text("まだ支出がありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var calendarModeContent: some View {
        VStack(spacing: 10) {
            monthHeader
            monthWeekdayHeader
            monthGrid

            if selectedDateExpenses.isEmpty {
                Text("選択日の支出はありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            } else {
                expenseTable(expenses: selectedDateExpenses)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonthStart = HistoryCalendar.monthOffset(from: displayedMonthStart, by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(HistoryFormatters.monthTitle.string(from: displayedMonthStart))
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                displayedMonthStart = HistoryCalendar.monthOffset(from: displayedMonthStart, by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
    }

    private var monthWeekdayHeader: some View {
        let symbols = HistoryCalendar.shortWeekdaySymbols

        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let cells = HistoryCalendar.monthCells(for: displayedMonthStart)

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
            ForEach(cells) { cell in
                if let date = cell.date {
                    let isSelected = HistoryCalendar.isSameDay(date, selectedDate)
                    let hasExpense = calendarDatesWithExpenses.contains(HistoryCalendar.dayStart(for: date))

                    Button {
                        selectedDate = date
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(HistoryCalendar.dayNumber(for: date))")
                                .font(.caption)
                                .foregroundStyle(isSelected ? Color.white : Color.primary)

                            Circle()
                                .fill(hasExpense ? (isSelected ? Color.white : Color.accentColor) : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(isSelected ? Color.accentColor : Color.clear)
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

    private func expenseTable(expenses: [ExpenseRecord]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                tableHeader

                ForEach(expenses, id: \.id) { expense in
                    NavigationLink {
                        HistoryExpenseDetailView(
                            expense: expense,
                            pocketName: pocketLabel(for: expense.pocketId),
                            categoryName: categoryLabel(for: expense.categoryId)
                        )
                    } label: {
                        expenseRow(expense)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
            .padding(.top, 4)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("日付")
                .frame(width: 74, alignment: .leading)

            Text("カテゴリ")
                .frame(width: 96, alignment: .leading)

            Text("メモ")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("支払元")
                .frame(width: 64, alignment: .center)

            Text("金額")
                .frame(width: 84, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: 0) {
            Text(HistoryFormatters.rowDate.string(from: expense.date))
                .frame(width: 74, alignment: .leading)

            Text(categoryLabel(for: expense.categoryId))
                .lineLimit(1)
                .frame(width: 96, alignment: .leading)

            Text(expense.memo.isEmpty ? "-" : expense.memo)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(paymentSourceLabel(expense.paymentSource))
                .frame(width: 64, alignment: .center)

            Text(HistoryFormatters.yen(expense.amount))
                .fontDesign(.monospaced)
                .frame(width: 84, alignment: .trailing)
        }
        .font(.caption)
        .padding(.vertical, 4)
    }

    private func paymentSourceLabel(_ source: PaymentSource) -> String {
        switch source {
        case .memberA:
            return "A"
        case .memberB:
            return "B"
        case .pocket:
            return "ポケット"
        }
    }

    private func categoryLabel(for categoryId: UUID?) -> String {
        guard let categoryId else {
            return "入金"
        }

        let category = CategoryCatalog.all.first(where: { $0.id == categoryId })
        return category?.displayName ?? "📦未分類"
    }

    private func pocketLabel(for pocketId: UUID) -> String {
        if let pocket = pocketRecords.first(where: { $0.id == pocketId })?.pocket {
            return deletedPocketIDs.contains(pocket.id) ? "\(pocket.name)（削除済み）" : pocket.name
        }

        return "未分類"
    }
}

private enum ViewMode {
    case calendar
    case list
}

private enum PocketFilter: Equatable {
    case total
    case pocket(UUID)
}

private struct PocketOption: Identifiable {
    let id: UUID
    let name: String
}

private struct CategoryCatalog {
    static let all: [CategoryDefinition] = [
        .init(id: UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!, displayName: "🛒食費"),
        .init(id: UUID(uuidString: "E8F9E3FD-6309-4FA4-B36B-D5CF5B0E56A7")!, displayName: "🧴生活"),
        .init(id: UUID(uuidString: "5C2EAE9B-349B-40BA-9817-9A0E13CE35F3")!, displayName: "🚃交通"),
        .init(id: UUID(uuidString: "BFE80144-9D6A-47B0-B4D9-83096E74CF23")!, displayName: "🎬娯楽"),
        .init(id: UUID(uuidString: "D2D8E4E9-D2A2-4C6A-840B-CCDBF07D82AD")!, displayName: "🧾その他"),
    ]
}

private struct CategoryDefinition {
    let id: UUID
    let displayName: String
}

private struct HistoryFormatters {
    static let rowDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "MM/dd(EEE)"
        return formatter
    }()

    static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let yenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func yen(_ amount: Int) -> String {
        let formatted = yenFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

private struct HistoryCalendar {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    static var shortWeekdaySymbols: [String] {
        calendar.veryShortStandaloneWeekdaySymbols
    }

    static func dayStart(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func monthOffset(from date: Date, by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: monthStart(for: date)) ?? date
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func monthCells(for monthStart: Date) -> [MonthCell] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekdayOfMonth = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        var cells = Array(repeating: MonthCell(date: nil), count: offset)

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(MonthCell(date: date))
            }
        }

        let trailingCount = (7 - (cells.count % 7)) % 7
        if trailingCount > 0 {
            cells.append(contentsOf: Array(repeating: MonthCell(date: nil), count: trailingCount))
        }

        return cells
    }
}

private struct MonthCell: Identifiable {
    let id = UUID()
    let date: Date?
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(PocketStore())
            .modelContainer(for: [ExpenseRecord.self, PocketRecord.self], inMemory: true)
    }
}
