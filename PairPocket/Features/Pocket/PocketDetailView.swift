import Charts
import SwiftData
import SwiftUI

struct PocketDetailView: View {
    @Query(sort: \PocketRecord.createdAt, order: .forward) private var pocketRecords: [PocketRecord]
    @Query(sort: \ExpenseRecord.date, order: .reverse) private var expenseRecords: [ExpenseRecord]
    @Query private var deletedPocketRecords: [DeletedPocketRecord]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(PocketStore.self) private var pocketStore

    let pocketID: UUID

    @State private var editingPocket: Pocket?
    @State private var isPresentingCategoryManagement = false
    @State private var isCategoryExpanded = true
    @State private var isMonthlyExpanded = false

    private let categoryPalette: [Color] = [
        .orange,
        .blue,
        .green,
        .pink,
        .teal,
        .indigo,
        .red,
        .mint
    ]

    private var deletedPocketIDs: Set<UUID> {
        Set(deletedPocketRecords.map(\.pocketId))
    }

    private var pocket: Pocket? {
        pocketRecords
            .first(where: { $0.id == pocketID && deletedPocketIDs.contains($0.id) == false })?
            .pocket
    }

    private var pocketExpenses: [Expense] {
        expenseRecords
            .map(\.pocketEntry)
            .filter { $0.pocketId == pocketID && $0.type == .expense }
            .sorted { $0.date > $1.date }
    }

    private var pocketCategories: [Category] {
        categoryStore.categories(for: pocketID)
    }

    private var totalAmount: Int {
        pocketExpenses.reduce(0) { $0 + $1.amount }
    }

    private var paidByA: Int {
        pocketExpenses
            .filter { $0.paymentSource == .host }
            .reduce(0) { $0 + $1.amount }
    }

    private var paidByB: Int {
        pocketExpenses
            .filter { $0.paymentSource == .partner }
            .reduce(0) { $0 + $1.amount }
    }

    private var settlementSummary: SettlementSummary {
        SettlementEngine.calculate(expenses: pocketExpenses)
    }

    private var categorySummaries: [CategorySpendingSummary] {
        var amountsByCategoryID = Dictionary(uniqueKeysWithValues: pocketCategories.map { ($0.id, 0) })
        var uncategorizedTotal = 0

        for expense in pocketExpenses {
            guard let categoryID = expense.categoryId else {
                uncategorizedTotal += expense.amount
                continue
            }

            if amountsByCategoryID[categoryID] != nil {
                amountsByCategoryID[categoryID, default: 0] += expense.amount
            } else {
                uncategorizedTotal += expense.amount
            }
        }

        var summaries = pocketCategories.compactMap { category -> CategorySpendingSummary? in
            let amount = amountsByCategoryID[category.id, default: 0]
            guard amount > 0 else { return nil }

            return CategorySpendingSummary(
                id: category.id,
                name: category.name,
                amount: amount
            )
        }

        if uncategorizedTotal > 0 {
            summaries.append(
                CategorySpendingSummary(
                    id: nil,
                    name: "未分類",
                    amount: uncategorizedTotal
                )
            )
        }

        return summaries.sorted { lhs, rhs in
            if lhs.amount == rhs.amount {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

            return lhs.amount > rhs.amount
        }
    }

    private var donutChartData: [CategorySpendingSummary] {
        if categorySummaries.isEmpty {
            return [
                CategorySpendingSummary(
                    id: nil,
                    name: "No Data",
                    amount: 1,
                    isPlaceholder: true
                )
            ]
        }

        return categorySummaries
    }

    private var chartYear: Int {
        let calendar = Calendar.current
        return pocketExpenses.first.map { calendar.component(.year, from: $0.date) }
            ?? calendar.component(.year, from: Date())
    }

    private var monthlySummaries: [MonthlySpendingSummary] {
        let calendar = Calendar.current
        var amountsByMonth = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, 0) })

        for expense in pocketExpenses {
            let year = calendar.component(.year, from: expense.date)
            guard year == chartYear else { continue }

            let month = calendar.component(.month, from: expense.date)
            amountsByMonth[month, default: 0] += expense.amount
        }

        return (1...12).map { month in
            MonthlySpendingSummary(
                month: month,
                amount: amountsByMonth[month, default: 0]
            )
        }
    }

    private var maxMonthlyAmount: Int {
        monthlySummaries.map(\.amount).max() ?? 0
    }

    var body: some View {
        Group {
            if let pocket {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PocketDetailSummary(
                            paidByA: paidByA,
                            paidByB: paidByB,
                            totalAmount: totalAmount,
                            formatYen: formatYen
                        )
                        PocketDetailSettlement(
                            payerName: settlementSummary.settlementPayer.map(memberName(for:)),
                            receiverName: settlementSummary.settlementReceiver.map(memberName(for:)),
                            settlementAmount: settlementSummary.settlementAmount,
                            formatYen: formatYen
                        )
                        PocketDetailCategorySection(
                            pocketColor: pocket.displayColor,
                            isExpanded: isCategoryExpanded,
                            categorySummaries: categorySummaries,
                            donutChartData: donutChartData,
                            totalAmount: totalAmount,
                            categoryCount: pocketCategories.count,
                            summaryText: categorySectionSummaryText,
                            formatYen: formatYen,
                            percentageText: percentageText(for:),
                            categoryColor: categoryColor(for:),
                            onToggle: toggleCategorySection,
                            onManageCategories: presentCategoryManagement
                        )
                        PocketDetailChart(
                            isExpanded: isMonthlyExpanded,
                            monthlySummaries: monthlySummaries,
                            isEmpty: pocketExpenses.isEmpty,
                            chartYear: chartYear,
                            summaryText: monthlySectionSummaryText,
                            formatYen: formatYen,
                            monthlyBarWidth: monthlyBarWidth(amount:availableWidth:),
                            onToggle: toggleMonthlySection
                        )
                    }
                    .padding(16)
                }
                .navigationTitle(pocket.name)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("編集") {
                            editingPocket = pocket
                        }
                    }
                }
            } else {
                ContentUnavailableView("ポケットが見つかりません", systemImage: "wallet.pass")
                    .navigationTitle("ポケット")
            }
        }
        .sheet(item: $editingPocket) { pocket in
            NavigationStack {
                PocketFormView(mode: .edit(pocket))
            }
        }
        .sheet(isPresented: $isPresentingCategoryManagement) {
            if let pocket {
                CategoryManagementSheet(pocket: pocket)
            }
        }
        .task {
            try? pocketStore.reload(from: modelContext)
            try? categoryStore.loadIfNeeded(from: modelContext)
            try? categoryStore.reload(from: modelContext)
        }
        .onChange(of: deletedPocketRecords.map(\.pocketId)) { _, _ in
            if pocket == nil {
                dismiss()
            }
        }
        .onChange(of: pocketRecords.map(\.id)) { _, _ in
            if pocket == nil {
                dismiss()
            }
        }
    }

    private func categoryColor(for summary: CategorySpendingSummary) -> Color {
        if summary.isPlaceholder {
            return Color(.systemGray4)
        }

        guard let categoryID = summary.id,
              let index = pocketCategories.firstIndex(where: { $0.id == categoryID }) else {
            return .gray
        }

        return categoryPalette[index % categoryPalette.count]
    }

    private func percentageText(for amount: Int) -> String {
        guard totalAmount > 0 else {
            return "0%"
        }

        let ratio = Double(amount) / Double(totalAmount)
        return "\(Int((ratio * 100).rounded()))%"
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }

    private var categorySectionSummaryText: String {
        if categorySummaries.isEmpty {
            return "カテゴリ別データはまだありません"
        }

        return "\(categorySummaries.count)項目を表示"
    }

    private var monthlySectionSummaryText: String {
        if pocketExpenses.isEmpty {
            return "\(chartYear)年の月別データはまだありません"
        }

        return "\(chartYear)年の12か月推移を表示"
    }

    private func memberName(for role: MemberRole) -> String {
        role.displayName
    }

    private func toggleMonthlySection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isMonthlyExpanded.toggle()
        }
    }

    private func toggleCategorySection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isCategoryExpanded.toggle()
        }
    }

    private func presentCategoryManagement() {
        isPresentingCategoryManagement = true
    }

    private func monthlyBarWidth(amount: Int, availableWidth: CGFloat) -> CGFloat {
        guard maxMonthlyAmount > 0 else {
            return 0
        }

        let ratio = CGFloat(amount) / CGFloat(maxMonthlyAmount)
        return max(availableWidth * ratio, amount > 0 ? 8 : 0)
    }

}

struct CategorySpendingSummary: Identifiable {
    let id: UUID?
    let name: String
    let amount: Int
    let isPlaceholder: Bool

    init(id: UUID?, name: String, amount: Int, isPlaceholder: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isPlaceholder = isPlaceholder
    }
}

struct MonthlySpendingSummary: Identifiable {
    let month: Int
    let amount: Int

    var id: Int { month }
    var label: String { "\(month)月" }
}

#Preview {
    NavigationStack {
        PocketDetailView(
            pocketID: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!
        )
        .environment(CategoryStore())
        .environment(PocketStore())
        .modelContainer(
            for: [ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self, CategoryRecord.self],
            inMemory: true
        )
    }
}
