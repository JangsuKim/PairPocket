import SwiftUI

struct SettlementExpenseSummarySection: View {
    let expenseSummaries: [SettlementExpenseSummary]
    let totalAmountText: String

    var body: some View {
        SettlementCardSection(title: "支出サマリー") {
            VStack(spacing: 12) {
                ForEach(expenseSummaries) { summary in
                    HStack(alignment: .center) {
                        Text(summary.memberName)
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 120, alignment: .leading)

                        Spacer()

                        Text(summary.amountText)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(MoneyValueStyle.color(forExpenseAmount: summary.amount))
                    }
                }

                Divider()

                HStack {
                    Text("合計")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(totalAmountText)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(totalAmountColor)
                }
            }
        }
    }

    private var totalAmountColor: Color {
        let totalAmount = expenseSummaries.reduce(0) { $0 + $1.amount }
        return MoneyValueStyle.color(forExpenseAmount: totalAmount)
    }
}
