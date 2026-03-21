import SwiftUI

struct SettlementSection: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @AppStorage(MemberPreferenceKeys.hostName) private var hostName = MemberRole.host.displayName
    @AppStorage(MemberPreferenceKeys.hostIcon) private var hostIcon = "person.circle.fill"
    @AppStorage(MemberPreferenceKeys.partnerName) private var partnerName = MemberRole.partner.displayName
    @AppStorage(MemberPreferenceKeys.partnerIcon) private var partnerIcon = "person.circle"

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
                arrowSystemName: "arrow.left.and.right",
                amountText: formattedYen(0)
            )
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver,
              summary.settlementAmount > 0 else {
            return HomeSettlementResultDisplay(
                arrowSystemName: "arrow.left.and.right",
                amountText: formattedYen(0)
            )
        }

        return HomeSettlementResultDisplay(
            arrowSystemName: arrowSystemName(payer: payer, receiver: receiver),
            amountText: formattedYen(summary.settlementAmount)
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
        .task {
            MemberPreferences.migrateLegacyValues()
        }
    }

    private var settlementAmountCard: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                MemberProfileView(
                    role: .host,
                    name: memberDisplayName(for: .host),
                    iconSystemName: memberIcon(for: .host),
                    avatarSize: 72
                )
                Spacer(minLength: 0)
                VStack(spacing: 4) {
                    if let arrowSystemName = settlementResultDisplay.arrowSystemName {
                        Image(systemName: arrowSystemName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(settlementResultDisplay.amountText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                Spacer(minLength: 0)
                MemberProfileView(
                    role: .partner,
                    name: memberDisplayName(for: .partner),
                    iconSystemName: memberIcon(for: .partner),
                    avatarSize: 72
                )
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
        case .host:
            return hostName.isEmpty ? MemberPreferences.fallbackName(for: role) : hostName
        case .partner:
            return partnerName.isEmpty ? MemberPreferences.fallbackName(for: role) : partnerName
        }
    }

    private func memberIcon(for role: MemberRole) -> String {
        switch role {
        case .host:
            return hostIcon
        case .partner:
            return partnerIcon
        }
    }

    private func arrowSystemName(payer: MemberRole, receiver: MemberRole) -> String {
        if payer == .host && receiver == .partner {
            return "arrow.right"
        }
        if payer == .partner && receiver == .host {
            return "arrow.left"
        }
        return "arrow.right"
    }

    private func formattedYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(formatted)円"
    }
}

private struct HomeSettlementResultDisplay {
    let arrowSystemName: String?
    let amountText: String
}

#Preview {
    SettlementSection()
}
