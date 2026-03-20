import SwiftUI

struct SettlementView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @AppStorage("settings.memberA.name") private var memberAName = "MemberA"
    @AppStorage("settings.memberA.icon") private var memberAIcon = "person.circle.fill"
    @AppStorage("settings.memberB.name") private var memberBName = "MemberB"
    @AppStorage("settings.memberB.icon") private var memberBIcon = "person.circle"

    @State private var selectedPocketID: String = "all"

    private var pocketOptions: [SettlementPocketOption] {
        [SettlementPocketOption(id: "all", title: "全体", color: .secondary)] + pocketStore.pockets.map {
            SettlementPocketOption(id: $0.id.uuidString, title: $0.name, color: $0.displayColor)
        }
    }

    private var selectedPocketUUID: UUID? {
        guard selectedPocketID != "all" else {
            return nil
        }

        return UUID(uuidString: selectedPocketID)
    }

    private var selectedPocketColor: Color {
        pocketOptions.first(where: { $0.id == selectedPocketID })?.color ?? .accentColor
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
                memberName: memberDisplayName(for: .memberA),
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByMemberA ?? 0)
            ),
            SettlementExpenseSummary(
                memberName: memberDisplayName(for: .memberB),
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
                fromMemberRole: nil,
                fromMemberName: nil,
                fromMemberIcon: nil,
                toMemberRole: nil,
                toMemberName: nil,
                toMemberIcon: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "未精算データがありません"
            )
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver,
              summary.settlementAmount > 0 else {
            return SettlementResultDisplay(
                fromMemberRole: nil,
                fromMemberName: nil,
                fromMemberIcon: nil,
                toMemberRole: nil,
                toMemberName: nil,
                toMemberIcon: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "精算は不要です"
            )
        }

        return SettlementResultDisplay(
            fromMemberRole: payer,
            fromMemberName: memberDisplayName(for: payer),
            fromMemberIcon: memberIcon(for: payer),
            toMemberRole: receiver,
            toMemberName: memberDisplayName(for: receiver),
            toMemberIcon: memberIcon(for: receiver),
            amountText: SettlementDisplayFormatter.yen(summary.settlementAmount),
            messageText: nil
        )
    }

    private func memberDisplayName(for role: MemberRole) -> String {
        switch role {
        case .memberA:
            return memberAName
        case .memberB:
            return memberBName
        }
    }

    private func memberIcon(for role: MemberRole) -> String {
        switch role {
        case .memberA:
            return memberAIcon
        case .memberB:
            return memberBIcon
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
                    fromMemberRole: settlementResultDisplay.fromMemberRole,
                    fromMemberName: settlementResultDisplay.fromMemberName,
                    fromMemberIcon: settlementResultDisplay.fromMemberIcon,
                    toMemberRole: settlementResultDisplay.toMemberRole,
                    toMemberName: settlementResultDisplay.toMemberName,
                    toMemberIcon: settlementResultDisplay.toMemberIcon,
                    amountText: settlementResultDisplay.amountText,
                    messageText: settlementResultDisplay.messageText,
                    accentColor: selectedPocketColor
                )
                SettlementActionSection(
                    buttonTitle: "精算を依頼",
                    tintColor: selectedPocketColor
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 116)
        }
        .background(Color(.systemGroupedBackground))
        .tint(selectedPocketColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("精算")
                    .font(.subheadline.weight(.semibold))
            }
        }
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
    let color: Color
}

struct SettlementExpenseSummary: Identifiable {
    let id = UUID()
    let memberName: String
    let amountText: String
}

private struct SettlementResultDisplay {
    let fromMemberRole: MemberRole?
    let fromMemberName: String?
    let fromMemberIcon: String?
    let toMemberRole: MemberRole?
    let toMemberName: String?
    let toMemberIcon: String?
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
