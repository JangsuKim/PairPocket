import SwiftUI

struct HomeView: View {
    @Environment(ExpenseStore.self) private var expenseStore

    private var totalExpense: Int {
        expenseStore.expenses.reduce(0) { $0 + $1.amount }
    }

    private var expenseCount: Int {
        expenseStore.expenses.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthlySummarySection(totalAmountYen: totalExpense, totalCount: expenseCount)
                QuickAddSection()
                SettlementSection()
            }
            .padding()
        }
        .navigationTitle("ペアポケ")
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(ExpenseStore())
    }
}
