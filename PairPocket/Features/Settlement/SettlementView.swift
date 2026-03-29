import SwiftData
import SwiftUI

struct SettlementView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @Environment(\.modelContext) private var modelContext
    @AppStorage(MemberPreferenceKeys.hostName) private var hostName = MemberRole.host.displayName
    @AppStorage(MemberPreferenceKeys.hostIcon) private var hostIcon = "person.circle.fill"
    @AppStorage(MemberPreferenceKeys.hostPhotoData) private var hostPhotoData = Data()
    @AppStorage(MemberPreferenceKeys.partnerName) private var partnerName = MemberRole.partner.displayName
    @AppStorage(MemberPreferenceKeys.partnerIcon) private var partnerIcon = "person.circle"
    @AppStorage(MemberPreferenceKeys.partnerPhotoData) private var partnerPhotoData = Data()

    @State private var selectedPocketID: String = "all"
    @State private var isShowingSettlementConfirmation = false
    @State private var isShowingZeroSettlementAlert = false

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
                memberName: memberDisplayName(for: .host),
                amount: summary?.totalPaidByHost ?? 0,
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByHost ?? 0)
            ),
            SettlementExpenseSummary(
                memberName: memberDisplayName(for: .partner),
                amount: summary?.totalPaidByPartner ?? 0,
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByPartner ?? 0)
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
                arrowAssetName: "SettlementArrowBidirectional",
                arrowSystemName: nil,
                amountText: SettlementDisplayFormatter.yenWithSuffix(0),
                amountColor: .primary,
                messageText: nil
            )
        }

        guard let signedAmount = SettlementResultPresenter.signedAmount(for: summary) else {
            return SettlementResultDisplay(
                arrowAssetName: "SettlementArrowBidirectional",
                arrowSystemName: nil,
                amountText: SettlementDisplayFormatter.yenWithSuffix(0),
                amountColor: .primary,
                messageText: nil
            )
        }

        return SettlementResultDisplay(
            arrowAssetName: SettlementResultPresenter.arrowAssetName(for: signedAmount),
            arrowSystemName: nil,
            amountText: SettlementDisplayFormatter.yenWithSuffix(abs(signedAmount)),
            amountColor: .primary,
            messageText: nil
        )
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
                    hostName: memberDisplayName(for: .host),
                    hostIcon: memberIcon(for: .host),
                    hostPhotoData: memberPhotoData(for: .host),
                    partnerName: memberDisplayName(for: .partner),
                    partnerIcon: memberIcon(for: .partner),
                    partnerPhotoData: memberPhotoData(for: .partner),
                    arrowAssetName: settlementResultDisplay.arrowAssetName,
                    arrowSystemName: settlementResultDisplay.arrowSystemName,
                    amountText: settlementResultDisplay.amountText,
                    amountColor: settlementResultDisplay.amountColor,
                    messageText: settlementResultDisplay.messageText,
                    accentColor: selectedPocketColor
                )
                SettlementActionSection(
                    buttonTitle: "精算を依頼",
                    tintColor: selectedPocketColor,
                    action: handleSettlementButtonTap
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .bottomTabBarContentInset()
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
        .background(settlementAlertHost)
    }

    private func executeSettlement() {
        guard selectedExpenses.isEmpty == false else {
            return
        }

        let settlementId = UUID()
        let settledAt = Date()

        try? expenseStore.settleExpenses(
            selectedExpenses,
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
                    executeSettlement()
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

struct SettlementPocketOption: Identifiable {
    let id: String
    let title: String
    let color: Color
}

struct SettlementExpenseSummary: Identifiable {
    let id = UUID()
    let memberName: String
    let amount: Int
    let amountText: String
}

private struct SettlementResultDisplay {
    let arrowAssetName: String?
    let arrowSystemName: String?
    let amountText: String
    let amountColor: Color
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

    static func yenWithSuffix(_ amount: Int) -> String {
        let formatted = yenFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(formatted)円"
    }
}

#Preview {
    NavigationStack {
        SettlementView()
    }
}
