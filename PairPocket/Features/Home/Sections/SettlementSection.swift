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
                arrowAssetName: "SettlementArrowBidirectional",
                arrowSystemName: nil,
                amountText: formattedYen(0)
            )
        }

        guard let signedAmount = signedSettlementAmount(for: summary) else {
            return HomeSettlementResultDisplay(
                arrowAssetName: "SettlementArrowBidirectional",
                arrowSystemName: nil,
                amountText: formattedYen(0)
            )
        }

        return HomeSettlementResultDisplay(
            arrowAssetName: settlementArrowAssetName(for: signedAmount),
            arrowSystemName: nil,
            amountText: formattedYen(abs(signedAmount))
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
            SettlementDirectionSummaryRow(
                hostName: memberDisplayName(for: .host),
                hostIcon: memberIcon(for: .host),
                partnerName: memberDisplayName(for: .partner),
                partnerIcon: memberIcon(for: .partner),
                amountText: settlementResultDisplay.amountText,
                arrowAssetName: settlementResultDisplay.arrowAssetName,
                arrowSystemName: settlementResultDisplay.arrowSystemName,
                avatarSize: 72,
                amountFont: .system(size: 20, weight: .bold, design: .rounded),
                arrowWidth: 70,
                arrowHeight: 40,
                centerMinWidth: 96,
                outerSpacing: 10,
                centerSpacing: 4,
                spacerMinLength: 0
            )
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

    private func signedSettlementAmount(for summary: SettlementSummary) -> Int? {
        if summary.settlementAmount == 0 {
            return 0
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver else {
            return nil
        }

        if payer == .host && receiver == .partner {
            return summary.settlementAmount
        }
        if payer == .partner && receiver == .host {
            return -summary.settlementAmount
        }
        return nil
    }

    private func settlementArrowAssetName(for signedAmount: Int) -> String {
        if signedAmount > 0 {
            return "SettlementArrowHostToPartner"
        }
        if signedAmount < 0 {
            return "SettlementArrowPartnerToHost"
        }
        return "SettlementArrowBidirectional"
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
    let arrowAssetName: String?
    let arrowSystemName: String?
    let amountText: String
}

#Preview {
    SettlementSection()
}
