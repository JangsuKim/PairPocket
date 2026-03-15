import SwiftUI

struct SettlementView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var selectedPocketID: String = "all"

    private var pocketOptions: [SettlementPocketOption] {
        [SettlementPocketOption(id: "all", title: "All")] + pocketStore.pockets.map {
            SettlementPocketOption(id: $0.id.uuidString, title: $0.name)
        }
    }

    private var selectedPocketUUID: UUID? {
        guard selectedPocketID != "all" else {
            return nil
        }

        return UUID(uuidString: selectedPocketID)
    }

    private var selectedExpenses: [Expense] {
        guard let pocketID = selectedPocketUUID else {
            return expenseStore.unsettledExpenses
        }

        return expenseStore.unsettledExpenses.filter { $0.pocketId == pocketID }
    }

    private var settlementSummary: SettlementSummary? {
        guard selectedExpenses.isEmpty == false else {
            return nil
        }

        return SettlementEngine.calculate(expenses: selectedExpenses)
    }

    private var expenseSummaries: [SettlementExpenseSummary] {
        let summary = settlementSummary

        return [
            SettlementExpenseSummary(
                memberName: memberName(for: .memberA),
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByMemberA ?? 0)
            ),
            SettlementExpenseSummary(
                memberName: memberName(for: .memberB),
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByMemberB ?? 0)
            )
        ]
    }

    private var totalAmountText: String {
        SettlementDisplayFormatter.yen(settlementSummary?.totalSpent ?? 0)
    }

    private var periodText: String {
        guard let summary = settlementSummary else {
            return "未精算データがありません"
        }

        return "\(SettlementDateFormatter.display.string(from: summary.periodStart)) → \(SettlementDateFormatter.display.string(from: summary.periodEnd))"
    }

    private var periodDurationText: String {
        guard let summary = settlementSummary else {
            return ""
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: summary.periodStart)
        let endDate = calendar.startOfDay(for: summary.periodEnd)
        let dayCount = max((calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1, 1)
        return "(\(dayCount)日間)"
    }

    private var settlementResultDisplay: SettlementResultDisplay {
        guard let summary = settlementSummary else {
            return SettlementResultDisplay(
                fromMemberName: nil,
                toMemberName: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "未精算データがありません"
            )
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver,
              summary.settlementAmount > 0 else {
            return SettlementResultDisplay(
                fromMemberName: nil,
                toMemberName: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "精算は不要です"
            )
        }

        return SettlementResultDisplay(
            fromMemberName: memberName(for: payer),
            toMemberName: memberName(for: receiver),
            amountText: SettlementDisplayFormatter.yen(summary.settlementAmount),
            messageText: nil
        )
    }

    private func memberName(for role: MemberRole) -> String {
        switch role {
        case .memberA:
            return "MemberA"
        case .memberB:
            return "MemberB"
        }
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
                        periodText: periodText,
                        durationText: periodDurationText
                    )
                }
                SettlementExpenseSummarySection(
                    expenseSummaries: expenseSummaries,
                    totalAmountText: totalAmountText
                )
                SettlementResultSection(
                    fromMemberName: settlementResultDisplay.fromMemberName,
                    toMemberName: settlementResultDisplay.toMemberName,
                    amountText: settlementResultDisplay.amountText,
                    messageText: settlementResultDisplay.messageText
                )
                SettlementActionSection(buttonTitle: "精算を依頼")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 116)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("精算")
        .onChange(of: pocketStore.pockets) { _, pockets in
            guard selectedPocketID != "all" else {
                return
            }

            let containsSelectedPocket = pockets.contains { $0.id.uuidString == selectedPocketID }
            if containsSelectedPocket == false {
                selectedPocketID = "all"
            }
        }
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

private struct SettlementResultDisplay {
    let fromMemberName: String?
    let toMemberName: String?
    let amountText: String
    let messageText: String?
}

private enum SettlementDateFormatter {
    static let display: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

private enum SettlementDisplayFormatter {
    static let yenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func yen(_ amount: Int) -> String {
        let formatted = yenFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

#Preview {
    NavigationStack {
        SettlementView()
    }
}
