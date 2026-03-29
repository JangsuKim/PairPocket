import SwiftUI

struct MonthlySummarySection: View {
    let summaryLabel: String
    let totalAmountYen: Int
    let totalCount: Int

    private var summaryTitle: String {
        HomeSummaryTextFormatter.summaryTitle(label: summaryLabel)
    }

    private var amountText: String {
        HomeSummaryTextFormatter.yenAmountText(totalAmountYen)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summaryTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(amountText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Spacer()
                Text("\(totalCount)件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    MonthlySummarySection(summaryLabel: "現在支出", totalAmountYen: 0, totalCount: 0)
}
