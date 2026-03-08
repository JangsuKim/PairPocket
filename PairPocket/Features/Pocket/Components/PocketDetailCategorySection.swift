import Charts
import SwiftUI

struct PocketDetailCategorySection: View {
    let pocketColor: Color
    let isExpanded: Bool
    let categorySummaries: [CategorySpendingSummary]
    let donutChartData: [CategorySpendingSummary]
    let totalAmount: Int
    let categoryCount: Int
    let summaryText: String
    let formatYen: (Int) -> String
    let percentageText: (Int) -> String
    let categoryColor: (CategorySpendingSummary) -> Color
    let onToggle: () -> Void
    let onManageCategories: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? 16 : 10) {
            HStack {
                Button {
                    onToggle()
                } label: {
                    HStack(spacing: 6) {
                        Text("カテゴリ支出")
                            .font(.headline)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button("カテゴリー管理") {
                    onManageCategories()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            if isExpanded {
                Chart(donutChartData) { summary in
                    SectorMark(
                        angle: .value("Amount", summary.amount),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(categoryColor(summary))
                }
                .frame(height: 220)
                .chartLegend(.hidden)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let frame = chartProxy.plotFrame {
                            let plotFrame = geometry[frame]

                            VStack(spacing: 4) {
                                Text("合計")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatYen(totalAmount))
                                    .font(.title3.weight(.bold))
                            }
                            .position(x: plotFrame.midX, y: plotFrame.midY)
                        }
                    }
                }

                if categorySummaries.isEmpty {
                    Text("カテゴリ別の支出データがありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(categorySummaries) { summary in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(categoryColor(summary))
                                    .frame(width: 10, height: 10)

                                Text(summary.name)
                                    .font(.subheadline)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(formatYen(summary.amount))
                                        .font(.subheadline.weight(.semibold))
                                    Text(percentageText(summary.amount))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if categoryCount == 0 {
                Text("このポケットにはまだカテゴリがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(categoryCount)個のカテゴリ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .tint(pocketColor)
    }
}

