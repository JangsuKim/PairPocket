import SwiftUI

struct SettlementExpenseSummarySection: View {
    let expenseSummaries: [SettlementExpenseSummary]
    let totalAmountText: String

    var body: some View {
        SettlementCardSection(title: "支出サマリー") {
            VStack(spacing: 12) {
                ForEach(expenseSummaries) { summary in
                    HStack {
                        Text(summary.memberName)
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        Text(summary.amountText)
                            .font(.system(.body, design: .rounded, weight: .bold))
                    }
                }

                Divider()

                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(totalAmountText)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
            }
        }
    }
}
