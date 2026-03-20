import SwiftUI

struct SettlementSection: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @AppStorage("settings.memberA.name") private var memberAName = "MemberA"
    @AppStorage("settings.memberA.icon") private var memberAIcon = "person.circle.fill"
    @AppStorage("settings.memberB.name") private var memberBName = "MemberB"
    @AppStorage("settings.memberB.icon") private var memberBIcon = "person.circle"

    private let allPocketColor: Color = .secondary

    private var unsettledExpenses: [Expense] {
        expenseStore.unsettledExpenses
    }

    private var settlementSummary: SettlementSummary? {
        guard unsettledExpenses.isEmpty == false else {
            return nil
        }

        return SettlementEngine.calculate(expenses: unsettledExpenses)
    }

    private var settlementResultDisplay: HomeSettlementResultDisplay {
        guard let summary = settlementSummary else {
            return HomeSettlementResultDisplay(
                fromMemberRole: nil,
                toMemberRole: nil,
                amountText: formattedYen(0),
                messageText: "未精算データがありません"
            )
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver,
              summary.settlementAmount > 0 else {
            return HomeSettlementResultDisplay(
                fromMemberRole: nil,
                toMemberRole: nil,
                amountText: formattedYen(0),
                messageText: "精算は不要です"
            )
        }

        return HomeSettlementResultDisplay(
            fromMemberRole: payer,
            toMemberRole: receiver,
            amountText: formattedYen(summary.settlementAmount),
            messageText: nil
        )
    }

    var body: some View {
        SettlementCardSection(title: "精算") {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("全ポケットの未精算をまとめて表示")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(unsettledExpenses.count)件")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                settlementAmountCard

                NavigationLink {
                    SettlementView()
                } label: {
                    Text("精算画面へ")
                        .frame(maxWidth: .infinity)
                        .frame(width: 140, height: 24)
                }
                .buttonStyle(.borderedProminent)
                .tint(allPocketColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var settlementAmountCard: some View {
        VStack(spacing: 6) {
            if let fromMemberRole = settlementResultDisplay.fromMemberRole,
               let toMemberRole = settlementResultDisplay.toMemberRole {
                HStack(spacing: 10) {
                    MemberProfileView(
                        role: fromMemberRole,
                        name: memberDisplayName(for: fromMemberRole),
                        iconSystemName: memberIcon(for: fromMemberRole),
                        avatarSize: 72
                    )
                    Spacer(minLength: 0)
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(settlementResultDisplay.amountText)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    Spacer(minLength: 0)
                    MemberProfileView(
                        role: toMemberRole,
                        name: memberDisplayName(for: toMemberRole),
                        iconSystemName: memberIcon(for: toMemberRole),
                        avatarSize: 72
                    )
                }
            } else if let messageText = settlementResultDisplay.messageText {
                Text(messageText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(allPocketColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

    private func formattedYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

private struct HomeSettlementResultDisplay {
    let fromMemberRole: MemberRole?
    let toMemberRole: MemberRole?
    let amountText: String
    let messageText: String?
}

#Preview {
    SettlementSection()
}
