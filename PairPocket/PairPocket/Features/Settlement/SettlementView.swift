import SwiftUI

struct SettlementView: View {
    @State private var selectedPocketID: String = "all"

    private let pocketOptions: [SettlementPocketOption] = [
        SettlementPocketOption(id: "all", title: "All"),
        SettlementPocketOption(id: "home", title: "Pocket A"),
        SettlementPocketOption(id: "travel", title: "Pocket B")
    ]

    private let expenseSummaries: [SettlementExpenseSummary] = [
        SettlementExpenseSummary(memberName: "A", amountText: "¥32,123"),
        SettlementExpenseSummary(memberName: "B", amountText: "¥12,500")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettlementPocketSelectorSection(
                    selectedPocketID: $selectedPocketID,
                    pocketOptions: pocketOptions
                )
                SettlementPeriodSection(periodText: "2026/03/01 → Today")
                SettlementExpenseSummarySection(expenseSummaries: expenseSummaries, totalAmountText: "¥44,623")
                SettlementResultSection(fromMemberName: "A", toMemberName: "B", amountText: "¥9,811")
                SettlementActionSection(buttonTitle: "精算を依頼")
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("精算")
    }
}

struct SettlementPocketOption: Identifiable {
    let id: String
    let title: String
}

struct SettlementExpenseSummary: Identifiable {
    let id = UUID()
    let memberName: String
    let amountText: String
}

#Preview {
    NavigationStack {
        SettlementView()
    }
}
