import SwiftUI

struct PocketDetailChart: View {
    let isExpanded: Bool
    let monthlySummaries: [MonthlySpendingSummary]
    let isEmpty: Bool
    let chartYear: Int
    let summaryText: String
    let formatYen: (Int) -> String
    let monthlyBarWidth: (Int, CGFloat) -> CGFloat
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 16 : 10) {
            Button {
                onToggle()
            } label: {
                HStack(spacing: 6) {
                    Text("月別支出")
                        .font(.headline)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(monthlySummaries) { summary in
                        monthlyBarRow(summary)
                    }
                }

                if isEmpty {
                    Text("\(chartYear)年の月別支出はまだありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(summaryText)
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
                            width: monthlyBarWidth(summary.amount, geometry.size.width),
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
}

