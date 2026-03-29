import SwiftData
import SwiftUI

struct SettlementSection: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(\.modelContext) private var modelContext
    @AppStorage(MemberPreferenceKeys.hostName) private var hostName = MemberRole.host.displayName
    @AppStorage(MemberPreferenceKeys.hostIcon) private var hostIcon = "person.circle.fill"
    @AppStorage(MemberPreferenceKeys.hostPhotoData) private var hostPhotoData = Data()
    @AppStorage(MemberPreferenceKeys.partnerName) private var partnerName = MemberRole.partner.displayName
    @AppStorage(MemberPreferenceKeys.partnerIcon) private var partnerIcon = "person.circle"
    @AppStorage(MemberPreferenceKeys.partnerPhotoData) private var partnerPhotoData = Data()
    @State private var isShowingSettlementConfirmation = false
    @State private var isShowingZeroSettlementAlert = false

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
                amountText: formattedYen(0),
                amountColor: .primary
            )
        }

        guard let signedAmount = SettlementResultPresenter.signedAmount(for: summary) else {
            return HomeSettlementResultDisplay(
                arrowAssetName: "SettlementArrowBidirectional",
                arrowSystemName: nil,
                amountText: formattedYen(0),
                amountColor: .primary
            )
        }

        return HomeSettlementResultDisplay(
            arrowAssetName: SettlementResultPresenter.arrowAssetName(for: signedAmount),
            arrowSystemName: nil,
            amountText: formattedYen(abs(signedAmount)),
            amountColor: .primary
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

                Button {
                    handleSettlementButtonTap()
                } label: {
                    Text("すべて精算する")
                        .frame(maxWidth: .infinity)
                        .frame(width: 140, height: 24)
                }
                .buttonStyle(.borderedProminent)
                .tint(allPocketColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(settlementAlertHost)
    }

    private var settlementAmountCard: some View {
        VStack(spacing: 6) {
            SettlementDirectionSummaryRow(
                hostName: memberDisplayName(for: .host),
                hostIcon: memberIcon(for: .host),
                hostPhotoData: memberPhotoData(for: .host),
                partnerName: memberDisplayName(for: .partner),
                partnerIcon: memberIcon(for: .partner),
                partnerPhotoData: memberPhotoData(for: .partner),
                amountText: settlementResultDisplay.amountText,
                amountColor: settlementResultDisplay.amountColor,
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

    private func memberPhotoData(for role: MemberRole) -> Data? {
        switch role {
        case .host:
            return hostPhotoData.isEmpty ? nil : hostPhotoData
        case .partner:
            return partnerPhotoData.isEmpty ? nil : partnerPhotoData
        }
    }

    private func formattedYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(formatted)円"
    }

    private func executeFullSettlement() {
        guard unsettledExpenses.isEmpty == false else {
            return
        }

        let settlementId = UUID()
        let settledAt = Date()

        try? expenseStore.settleExpenses(
            unsettledExpenses,
            settlementId: settlementId,
            settledAt: settledAt,
            in: modelContext
        )
    }

    private func handleSettlementButtonTap() {
        let settlementAmount = settlementSummary?.settlementAmount ?? 0

        switch SettlementAlertContent.kind(for: settlementAmount) {
        case .confirmation:
            isShowingSettlementConfirmation = true
        case .zeroAmount:
            isShowingZeroSettlementAlert = true
        }
    }

    @ViewBuilder
    private var settlementAlertHost: some View {
        Color.clear
            .tint(.blue)
            .alert(SettlementAlertContent.confirmationTitle, isPresented: $isShowingSettlementConfirmation) {
                Button(SettlementAlertContent.cancelButtonTitle, role: .cancel) {
                }
                Button(SettlementAlertContent.confirmButtonTitle) {
                    executeFullSettlement()
                }
            } message: {
                Text(SettlementAlertContent.confirmationMessage)
            }
            .alert(SettlementAlertContent.zeroAmountTitle, isPresented: $isShowingZeroSettlementAlert) {
                Button(SettlementAlertContent.okButtonTitle, role: .cancel) {
                }
            } message: {
                Text(SettlementAlertContent.zeroAmountMessage)
            }
    }
}

private struct HomeSettlementResultDisplay {
    let arrowAssetName: String?
    let arrowSystemName: String?
    let amountText: String
    let amountColor: Color
}

#Preview {
    SettlementSection()
}
