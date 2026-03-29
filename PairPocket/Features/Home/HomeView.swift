import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPocket: Pocket?

    private var currentMonthExpenseTotal: Int {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var currentMonthExpenseCount: Int {
        currentMonthExpenses.count
    }

    private var selectedPocketEntries: [Transaction] {
        guard let selectedPocket else {
            return []
        }

        return expenseStore.entries(for: selectedPocket.id)
    }

    private var selectedPocketBalance: Int {
        SettlementEngine.calculate(entries: selectedPocketEntries).currentBalance
    }

    private var currentMonthEntries: [Transaction] {
        let monthEntries = expenseStore.currentMonthEntries()

        guard let selectedPocket else {
            return monthEntries
        }

        return monthEntries.filter { $0.pocketId == selectedPocket.id }
    }

    private var currentMonthExpenses: [Expense] {
        currentMonthEntries.filter { $0.type == .expense }
    }

    private var pocketSummaryLabel: String {
        selectedPocket?.mode == .sharedManagement ? "現在残高" : "現在支出"
    }

    private var pocketSummaryAmount: Int {
        selectedPocket?.mode == .sharedManagement ? selectedPocketBalance : currentMonthExpenseTotal
    }

    private var pocketSummaryCount: Int {
        selectedPocket?.mode == .sharedManagement ? selectedPocketEntries.count : currentMonthExpenseCount
    }

    var body: some View {
        let pockets = pocketStore.pockets
        let pocketColor = selectedPocket?.displayColor ?? .accentColor

        ScrollView {
            VStack(spacing: 12) {
                if pockets.isEmpty == false {
                    PocketSummarySection(
                        pockets: pockets,
                        selectedPocket: selectedPocket,
                        summaryLabel: pocketSummaryLabel,
                        totalAmountYen: pocketSummaryAmount,
                        totalCount: pocketSummaryCount,
                        onSelectPocket: { pocket in
                            selectedPocket = pocket
                        }
                    )
                } else {
                    MonthlySummarySection(
                        summaryLabel: "現在支出",
                        totalAmountYen: currentMonthExpenseTotal,
                        totalCount: currentMonthExpenseCount
                    )
                }
                QuickAddSection(selectedPocket: selectedPocket)
                SettlementSection()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .bottomTabBarContentInset()
        }
        .tint(pocketColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("ペアポケ")
                    .font(.subheadline.weight(.semibold))
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("設定")
            }
        }
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
