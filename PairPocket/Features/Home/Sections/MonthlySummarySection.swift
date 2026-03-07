import SwiftUI

struct MonthlySummarySection: View {
    let totalAmountYen: Int
    let totalCount: Int

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: Date())) 現在出費"
    }

    private var amountText: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: totalAmountYen)) ?? "0"
        return "¥\(formatted)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todayLabel)
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
    MonthlySummarySection(totalAmountYen: 0, totalCount: 0)
}
