import SwiftUI

struct PocketDetailView: View {
    let pocket: Pocket

    private let paymentSummary = PaymentSummary(personAAmount: 53_200, personBAmount: 50_200)

    private let categoryBreakdown: [CategoryShare] = [
        .init(name: "Supermarket", percentage: 0.32),
        .init(name: "Drugstore", percentage: 0.18),
        .init(name: "Online", percentage: 0.21),
        .init(name: "Restaurant", percentage: 0.19),
        .init(name: "Others", percentage: 0.10),
    ]

    private let monthlyTrend: [MonthlyAmount] = [
        .init(month: 1, amountYen: 8_200),
        .init(month: 2, amountYen: 9_600),
        .init(month: 3, amountYen: 7_400),
        .init(month: 4, amountYen: 8_800),
        .init(month: 5, amountYen: 9_200),
        .init(month: 6, amountYen: 10_500),
        .init(month: 7, amountYen: 11_300),
        .init(month: 8, amountYen: 12_100),
        .init(month: 9, amountYen: 10_400),
        .init(month: 10, amountYen: 9_100),
        .init(month: 11, amountYen: 8_900),
        .init(month: 12, amountYen: 11_800),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                paymentSummarySection
                categoryBreakdownSection
                settlementSection
                monthlyTrendSection
            }
            .padding()
        }
        .navigationTitle(pocket.name)
    }

    private var paymentSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Summary")
                .font(.headline)

            summaryRow(title: "Person A", amount: paymentSummary.personAAmount)
            summaryRow(title: "Person B", amount: paymentSummary.personBAmount)

            Divider()

            summaryRow(title: "Total", amount: paymentSummary.totalAmount, isEmphasized: true)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Breakdown")
                .font(.headline)

            ForEach(categoryBreakdown) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        Text("\(Int(item.percentage * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: item.percentage)
                        .tint(.blue)
                }
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var settlementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Settlement Summary")
                .font(.headline)
            Text("A → B \(formatYen(3_000))")
                .font(.title3.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trend")
                .font(.headline)

            let maxValue = monthlyTrend.map(\.amountYen).max() ?? 1

            ForEach(monthlyTrend) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(item.month)")
                            .frame(width: 28, alignment: .leading)
                        ProgressView(value: Double(item.amountYen), total: Double(maxValue))
                            .tint(.green)
                        Text(formatYen(item.amountYen))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func summaryRow(title: String, amount: Int, isEmphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatYen(amount))
                .fontWeight(isEmphasized ? .bold : .regular)
        }
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

private struct PaymentSummary {
    let personAAmount: Int
    let personBAmount: Int

    var totalAmount: Int {
        personAAmount + personBAmount
    }
}

private struct CategoryShare: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
}

private struct MonthlyAmount: Identifiable {
    let id = UUID()
    let month: Int
    let amountYen: Int
}

#Preview {
    NavigationStack {
        PocketDetailView(pocket: .init(id: 0, name: "Total", amountYen: 146_624, count: 12))
    }
}
