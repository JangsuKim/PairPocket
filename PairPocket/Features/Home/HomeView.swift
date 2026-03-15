import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPocket: Pocket?

    private var monthlyTotal: Int {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var monthlyCount: Int {
        currentMonthExpenses.count
    }

    private var currentMonthExpenses: [Expense] {
        let monthExpenses = expenseStore.currentMonthExpenses()

        guard let selectedPocket else {
            return monthExpenses
        }

        return monthExpenses.filter { $0.pocketId == selectedPocket.id }
    }

    var body: some View {
        let pockets = pocketStore.pockets
        let pocketColor = selectedPocket?.displayColor ?? .accentColor

        ScrollView {
            VStack(spacing: 16) {
                if pockets.isEmpty == false {
                    PocketSummarySection(
                        pockets: pockets,
                        selectedPocket: selectedPocket,
                        totalAmountYen: monthlyTotal,
                        totalCount: monthlyCount,
                        onSelectPocket: { pocket in
                            selectedPocket = pocket
                        }
                    )
                } else {
                    MonthlySummarySection(totalAmountYen: monthlyTotal, totalCount: monthlyCount)
                }
                QuickAddSection()
                SettlementSection()
            }
            .padding()
        }
        .tint(pocketColor)
        .navigationTitle("ペアポケ")
        .task {
            try? expenseStore.loadIfNeeded(from: modelContext)
            try? pocketStore.loadIfNeeded(from: modelContext)
            syncSelectedPocket()
        }
        .onChange(of: pocketStore.pockets.map(\.id)) { _, _ in
            syncSelectedPocket()
        }
    }

    private func syncSelectedPocket() {
        let pockets = pocketStore.pockets

        guard pockets.isEmpty == false else {
            selectedPocket = nil
            return
        }

        if let selectedPocket,
           pockets.contains(where: { $0.id == selectedPocket.id }) {
            return
        }

        selectedPocket = pocketStore.mainPocket ?? pockets.first
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .modelContainer(for: [ExpenseRecord.self], inMemory: true)
    }
}
