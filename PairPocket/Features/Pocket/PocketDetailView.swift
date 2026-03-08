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
            .filter { $0.paymentSource == .memberA }
            .reduce(0) { $0 + $1.amount }
    }

    private var paidByB: Int {
        pocketExpenses
            .filter { $0.paymentSource == .memberB }
            .reduce(0) { $0 + $1.amount }
    }

    private var settlementSummary: SettlementSummary {
        SettlementCalculator.calculate(expenses: pocketExpenses)
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
                        summarySection
                        settlementSection
                        categorySection(for: pocket)
                        monthlySection
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

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("支出サマリー")
                .font(.headline)

            summaryAmountRow(title: "MemberA", amount: paidByA)
            summaryAmountRow(title: "MemberB", amount: paidByB)

            Divider()

            summaryAmountRow(title: "合計", amount: totalAmount, emphasized: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var settlementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精算予定")
                .font(.headline)

            Text("現在の精算予定額")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let payer = settlementSummary.settlementPayer,
               let receiver = settlementSummary.settlementReceiver,
               settlementSummary.settlementAmount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(memberName(for: payer)) → \(memberName(for: receiver))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(formatYen(settlementSummary.settlementAmount))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
            } else {
                Text("精算なし")
                    .font(.title3.weight(.bold))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func categorySection(for pocket: Pocket) -> some View {
        VStack(alignment: .leading, spacing: isCategoryExpanded ? 16 : 10) {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCategoryExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("カテゴリ支出")
                            .font(.headline)
                        Image(systemName: isCategoryExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
                Button("カテゴリー管理") {
                    isPresentingCategoryManagement = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            if isCategoryExpanded {
                Chart(donutChartData) { summary in
                    SectorMark(
                        angle: .value("Amount", summary.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(categoryColor(for: summary))
                }
                .frame(height: 220)
                .chartLegend(.hidden)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let frame = chartProxy.plotFrame {
                            let plotFrame = geometry[frame]

                            VStack(spacing: 4) {
                                Text("合計")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatYen(totalAmount))
                                    .font(.title3.weight(.bold))
                            }
                            .position(x: plotFrame.midX, y: plotFrame.midY)
                        }
                    }
                }

                if categorySummaries.isEmpty {
                    Text("カテゴリ別の支出データがありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(categorySummaries) { summary in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(categoryColor(for: summary))
                                    .frame(width: 10, height: 10)

                                Text(summary.name)
                                    .font(.subheadline)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatYen(summary.amount))
                                        .font(.subheadline.weight(.semibold))
                                    Text(percentageText(for: summary.amount))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Text(categorySectionSummaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if pocketCategories.isEmpty {
                Text("このポケットにはまだカテゴリがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(pocketCategories.count)個のカテゴリ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .tint(pocket.displayColor)
    }

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: isMonthlyExpanded ? 16 : 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMonthlyExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text("月別支出")
                        .font(.headline)
                    Image(systemName: isMonthlyExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isMonthlyExpanded {
                VStack(spacing: 10) {
                    ForEach(monthlySummaries) { summary in
                        monthlyBarRow(summary)
                    }
                }

                if pocketExpenses.isEmpty {
                    Text("\(chartYear)年の月別支出はまだありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(monthlySectionSummaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func monthlyBarRow(_ summary: MonthlySpendingSummary) -> some View {
        HStack(spacing: 12) {
            Text(summary.label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue.gradient)
                        .frame(
                            width: monthlyBarWidth(
                                amount: summary.amount,
                                availableWidth: geometry.size.width
                            ),
                            height: 12
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(height: 20)

            Text(formatYen(summary.amount))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }

    private func summaryAmountRow(title: String, amount: Int, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .fontWeight(emphasized ? .semibold : .regular)
            Spacer()
            Text(formatYen(amount))
                .font(emphasized ? .title3.weight(.bold) : .title3.weight(.semibold))
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
        switch role {
        case .memberA:
            return "MemberA"
        case .memberB:
            return "MemberB"
        }
    }

    private func monthlyBarWidth(amount: Int, availableWidth: CGFloat) -> CGFloat {
        guard maxMonthlyAmount > 0 else {
            return 0
        }

        let ratio = CGFloat(amount) / CGFloat(maxMonthlyAmount)
        return max(availableWidth * ratio, amount > 0 ? 8 : 0)
    }

}

private struct CategorySpendingSummary: Identifiable {
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

private struct MonthlySpendingSummary: Identifiable {
    let month: Int
    let amount: Int

    var id: Int { month }
    var label: String { "\(month)月" }
}

private struct CategoryManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore

    let pocket: Pocket

    @State private var newCategoryName = ""
    @State private var errorMessage: String?

    private var categories: [Category] {
        categoryStore.categories(for: pocket.id)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("カテゴリ一覧") {
                    if categories.isEmpty {
                        Text("カテゴリがありません")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { category in
                            EditableCategoryRow(category: category) { updatedName in
                                do {
                                    try categoryStore.renameCategory(id: category.id, to: updatedName, in: modelContext)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            } onDelete: {
                                do {
                                    try categoryStore.deleteCategory(id: category.id, in: modelContext)
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                    }
                }

                Section("カテゴリ追加") {
                    HStack(spacing: 12) {
                        TextField("新しいカテゴリ名", text: $newCategoryName)

                        Button("追加") {
                            do {
                                _ = try categoryStore.addCategory(
                                    name: newCategoryName,
                                    to: pocket.id,
                                    in: modelContext
                                )
                                newCategoryName = ""
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("カテゴリー管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .task {
                try? categoryStore.loadIfNeeded(from: modelContext)
                try? categoryStore.reload(from: modelContext)
            }
            .alert("保存に失敗しました", isPresented: errorAlertBinding) {
                Button("確認", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました。")
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    errorMessage = nil
                }
            }
        )
    }
}

private struct EditableCategoryRow: View {
    let category: Category
    let onSave: (String) -> Void
    let onDelete: () -> Void

    @State private var draftName: String

    init(
        category: Category,
        onSave: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.category = category
        self.onSave = onSave
        self.onDelete = onDelete
        _draftName = State(initialValue: category.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("カテゴリ名", text: $draftName)

            Button("保存") {
                onSave(draftName)
            }
            .disabled(trimmedDraftName.isEmpty || trimmedDraftName == category.name)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
    }

    private var trimmedDraftName: String {
        draftName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
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
