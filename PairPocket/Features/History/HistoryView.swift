import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ExpenseRecord.date, order: .reverse) private var expenses: [ExpenseRecord]
    @Query(sort: \PocketRecord.createdAt, order: .forward) private var pocketRecords: [PocketRecord]
    @Query private var deletedPocketRecords: [DeletedPocketRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var selectedFilter: PocketFilter = .total
    @State private var selectedMode: ViewMode = .calendar
    @State private var displayedMonthStart: Date = HistoryCalendar.monthStart(for: Date())
    @State private var selectedDate: Date = HistoryCalendar.dayStart(for: Date())

    private let overallAccentColor: Color = .secondary
    private let localUserId = MemberPreferences.ensureLocalUserId()
    private let rowLayout = HistoryRowLayout.self

    var body: some View {
        VStack(spacing: 12) {
            pocketFilterTabs
            monthNavigationRow
            modeSwitcher

            if selectedMode == .calendar {
                calendarModeContent
            } else {
                if selectedMonthExpenses.isEmpty {
                    emptyState
                } else {
                    listModeContent
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("履歴")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .onAppear {
            resetCalendarToToday()
        }
        .onChange(of: selectedMode) { _, newValue in
            guard newValue == .calendar else {
                return
            }

            resetCalendarToToday()
        }
        .task {
            try? pocketStore.loadIfNeeded(from: modelContext)
            try? categoryStore.loadIfNeeded(from: modelContext)
        }
    }

    private var filteredExpenses: [ExpenseRecord] {
        let activeExpenses = expenses.filter { $0.deletedAt == nil }

        switch selectedFilter {
        case .total:
            return activeExpenses
        case let .pocket(id):
            return activeExpenses.filter { $0.pocketId == id }
        }
    }

    private var selectedMonthExpenses: [ExpenseRecord] {
        filteredExpenses.filter { HistoryCalendar.isSameMonth($0.date, displayedMonthStart) }
    }

    private var unsettledMonthExpenses: [ExpenseRecord] {
        selectedMonthExpenses.filter { $0.isSettled == false }
    }

    private var settledMonthExpenses: [ExpenseRecord] {
        selectedMonthExpenses.filter(\.isSettled)
    }

    private var deletedPocketIDs: Set<UUID> {
        Set(deletedPocketRecords.map(\.pocketId))
    }

    private var pocketOptions: [PocketOption] {
        pocketRecords
            .filter { deletedPocketIDs.contains($0.id) == false }
            .map(\.pocket)
            .map {
                PocketOption(id: $0.id, name: $0.name, color: $0.displayColor)
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
                PocketSelectionChip(
                    title: "全体",
                    color: .secondary,
                    isSelected: selectedFilter == .total
                ) {
                    selectedFilter = .total
                }

                ForEach(pocketOptions) { option in
                    if let pocketID = option.id {
                        PocketSelectionChip(
                            title: option.name,
                            color: option.color,
                            isSelected: selectedFilter == .pocket(pocketID)
                        ) {
                            selectedFilter = .pocket(pocketID)
                        }
                    }
                }
            }
        }
    }

    private var modeSwitcher: some View {
        Picker("表示", selection: $selectedMode) {
            Text("カレンダー").tag(ViewMode.calendar)
            Text("リスト").tag(ViewMode.list)
        }
        .pickerStyle(.segmented)
    }

    private var monthNavigationRow: some View {
        HistoryMonthHeader(
            displayedMonthStart: displayedMonthStart,
            onPreviousMonth: { moveDisplayedMonth(by: -1) },
            onNextMonth: { moveDisplayedMonth(by: 1) }
        )
    }

    private var emptyState: some View {
        VStack {
            Spacer(minLength: 36)
            Text("選択した月の支出はありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var calendarModeContent: some View {
        VStack(spacing: 10) {
            HistoryMonthWeekdayHeader()
            HistoryMonthGrid(
                displayedMonthStart: displayedMonthStart,
                datesWithExpenses: calendarDatesWithExpenses,
                accentColor: overallAccentColor,
                selectedDate: $selectedDate
            )

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

    private var listModeContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                tableHeader

                if unsettledMonthExpenses.isEmpty == false {
                    expenseSection(title: "未精算", expenses: unsettledMonthExpenses)
                }

                if settledMonthExpenses.isEmpty == false {
                    expenseSection(title: "精算済み", expenses: settledMonthExpenses)
                }
            }
            .padding(.top, 4)
            .bottomTabBarContentInset()
        }
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
            .bottomTabBarContentInset()
        }
    }

    private func expenseSection(title: String, expenses: [ExpenseRecord]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 12)
                .padding(.bottom, 6)

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
    }

    private var tableHeader: some View {
        HStack(spacing: rowLayout.columnSpacing) {
            Text("日付")
                .frame(width: rowLayout.dateWidth, alignment: .center)

            Text("カテゴリ")
                .frame(width: rowLayout.categoryWidth, alignment: .center)

            Text("支払元")
                .frame(width: rowLayout.payerWidth, alignment: .trailing)

            Text("金額")
                .frame(width: rowLayout.amountWidth, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
    }

    private func expenseRow(_ expense: ExpenseRecord) -> some View {
        HStack(spacing: rowLayout.columnSpacing) {
            HStack(spacing: 8) {
                Circle()
                    .fill(pocketColor(for: expense.pocketId))
                    .frame(width: 8, height: 8)

                Text(HistoryFormatters.rowDate.string(from: expense.date))
            }
            .frame(width: rowLayout.dateWidth, alignment: .leading)

            Text(categoryLabel(for: expense.categoryId))
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.95)
                .frame(width: rowLayout.categoryWidth, alignment: .leading)

            Text(payerLabel(for: expense))
                .lineLimit(1)
                .frame(width: rowLayout.payerWidth, alignment: .trailing)

            Text(HistoryFormatters.yen(expense.amount))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(entryTypeColor(for: expense))
                .frame(width: rowLayout.amountWidth, alignment: .trailing)
        }
        .font(.callout)
        .padding(.vertical, 8)
        .frame(minHeight: rowLayout.minHeight)
    }

    private func entryTypeColor(for expense: ExpenseRecord) -> Color {
        MoneyValueStyle.color(for: expense.entryType)
    }

    private func payerLabel(for expense: ExpenseRecord) -> String {
        MemberPreferences.payerMemberName(
            paymentSource: expense.paymentSource,
            paidByUserId: expense.paidByUserId,
            localUserId: localUserId
        )
    }

    private func categoryLabel(for categoryId: UUID?) -> String {
        guard let categoryId else {
            return "入金"
        }

        let category = categoryStore.categories.first(where: { $0.id == categoryId })
        return category?.name ?? "未分類"
    }

    private func pocketLabel(for pocketId: UUID) -> String {
        if let pocket = pocketRecords.first(where: { $0.id == pocketId })?.pocket {
            return deletedPocketIDs.contains(pocket.id) ? "\(pocket.name)（削除済み）" : pocket.name
        }

        return "未分類"
    }

    private func pocketColor(for pocketId: UUID) -> Color {
        pocketRecords.first(where: { $0.id == pocketId })?.pocket.displayColor ?? .gray
    }

    private func resetCalendarToToday() {
        let today = Date()
        displayedMonthStart = HistoryCalendar.monthStart(for: today)
        selectedDate = HistoryCalendar.dayStart(for: today)
    }

    private func moveDisplayedMonth(by value: Int) {
        let monthStart = HistoryCalendar.monthOffset(from: displayedMonthStart, by: value)
        displayedMonthStart = monthStart
        selectedDate = preferredSelectedDate(for: monthStart)
    }

    private func preferredSelectedDate(for monthStart: Date) -> Date {
        let latestExpenseDate = filteredExpenses
            .filter { HistoryCalendar.isSameMonth($0.date, monthStart) }
            .map(\.date)
            .max()

        if let latestExpenseDate {
            return HistoryCalendar.dayStart(for: latestExpenseDate)
        }

        return monthStart
    }
}

private enum HistoryRowLayout {
    static let dateWidth: CGFloat = 68
    static let categoryWidth: CGFloat = 104
    static let payerWidth: CGFloat = 50
    static let amountWidth: CGFloat = 100
    static let columnSpacing: CGFloat = 8
    static let minHeight: CGFloat = 44
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
    let id: UUID?
    let name: String
    let color: Color
}

#Preview {
    NavigationStack {
        HistoryView()
            .environment(PocketStore())
            .modelContainer(for: [ExpenseRecord.self, PocketRecord.self], inMemory: true)
    }
}
