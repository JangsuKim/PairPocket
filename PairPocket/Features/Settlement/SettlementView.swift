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

    private let settlementStartDate = Calendar.current.date(
        from: DateComponents(year: 2026, month: 3, day: 1)
    ) ?? Date()

    private var todayText: String {
        SettlementDateFormatter.display.string(from: Date())
    }

    private var periodDurationText: String {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: settlementStartDate)
        let endDate = calendar.startOfDay(for: Date())
        let dayCount = max((calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1, 1)
        return "(\(dayCount)日間)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    SettlementPocketSelectorSection(
                        selectedPocketID: $selectedPocketID,
                        pocketOptions: pocketOptions
                    )
                    SettlementPeriodSection(
                        periodText: "2026/03/01 → \(todayText)",
                        durationText: periodDurationText
                    )
                }
                SettlementExpenseSummarySection(expenseSummaries: expenseSummaries, totalAmountText: "¥44,623")
                SettlementResultSection(fromMemberName: "A", toMemberName: "B", amountText: "¥9,811")
                SettlementActionSection(buttonTitle: "精算を依頼")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 116)
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

private enum SettlementDateFormatter {
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

#Preview {
    NavigationStack {
        SettlementView()
    }
}
