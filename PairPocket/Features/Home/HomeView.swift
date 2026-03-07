import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var expenses: [ExpenseRecord]

    private var currentMonthExpenses: [ExpenseRecord] {
        expenses.filter { isInCurrentMonth($0.date) }
    }

    private var monthlyTotal: Int {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var monthlyCount: Int {
        currentMonthExpenses.count
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
    }

    private func isInCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [ExpenseRecord.self], inMemory: true)
    }
}
