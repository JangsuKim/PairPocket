import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(\.modelContext) private var modelContext

    private var monthlyTotal: Int {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var monthlyCount: Int {
        currentMonthExpenses.count
    }

    private var currentMonthExpenses: [Expense] {
        expenseStore.currentMonthExpenses()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthlySummarySection(totalAmountYen: monthlyTotal, totalCount: monthlyCount)
                QuickAddSection()
                SettlementSection()
            }
            .padding()
        }
        .navigationTitle("ペアポケ")
        .task {
            try? expenseStore.loadIfNeeded(from: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [ExpenseRecord.self], inMemory: true)
    }
}
