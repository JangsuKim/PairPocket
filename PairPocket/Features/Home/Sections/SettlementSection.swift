import SwiftUI

struct SettlementSection: View {
    @Environment(ExpenseStore.self) private var expenseStore

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
                fromMemberName: nil,
                toMemberName: nil,
                amountText: formattedYen(0),
                messageText: "未精算データがありません"
            )
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver,
              summary.settlementAmount > 0 else {
            return HomeSettlementResultDisplay(
                fromMemberName: nil,
                toMemberName: nil,
                amountText: formattedYen(0),
                messageText: "精算は不要です"
            )
        }

        return HomeSettlementResultDisplay(
            fromMemberName: memberName(for: payer),
            toMemberName: memberName(for: receiver),
            amountText: formattedYen(summary.settlementAmount),
            messageText: nil
        )
    }

    var body: some View {
        SettlementCardSection(title: "精算") {
            VStack(alignment: .leading, spacing: 10) {
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
                .tint(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var settlementAmountCard: some View {
        VStack(spacing: 8) {
            if let fromMemberName = settlementResultDisplay.fromMemberName,
               let toMemberName = settlementResultDisplay.toMemberName {
                HStack(spacing: 10) {
                    UserChip(name: fromMemberName)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    UserChip(name: toMemberName)
                }
            } else if let messageText = settlementResultDisplay.messageText {
                Text(messageText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(settlementResultDisplay.amountText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func memberName(for role: MemberRole) -> String {
        switch role {
        case .memberA:
            return "memberA"
        case .memberB:
            return "memberB"
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
    let fromMemberName: String?
    let toMemberName: String?
    let amountText: String
    let messageText: String?
}

#Preview {
    SettlementSection()
}
