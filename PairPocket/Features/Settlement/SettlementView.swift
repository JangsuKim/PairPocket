import SwiftUI

struct SettlementView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore
    @AppStorage(MemberPreferenceKeys.hostName) private var hostName = MemberRole.host.displayName
    @AppStorage(MemberPreferenceKeys.hostIcon) private var hostIcon = "person.circle.fill"
    @AppStorage(MemberPreferenceKeys.hostPhotoData) private var hostPhotoData = Data()
    @AppStorage(MemberPreferenceKeys.partnerName) private var partnerName = MemberRole.partner.displayName
    @AppStorage(MemberPreferenceKeys.partnerIcon) private var partnerIcon = "person.circle"
    @AppStorage(MemberPreferenceKeys.partnerPhotoData) private var partnerPhotoData = Data()

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
                memberName: memberDisplayName(for: .host),
                amountText: SettlementDisplayFormatter.yen(summary?.totalPaidByHost ?? 0)
            ),
            SettlementExpenseSummary(
                memberName: memberDisplayName(for: .partner),
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
                arrowAssetName: nil,
                arrowSystemName: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "未精算データがありません"
            )
        }

        guard let signedAmount = signedSettlementAmount(for: summary) else {
            return SettlementResultDisplay(
                arrowAssetName: nil,
                arrowSystemName: nil,
                amountText: SettlementDisplayFormatter.yen(0),
                messageText: "精算は不要です"
            )
        }

        return SettlementResultDisplay(
            arrowAssetName: settlementArrowAssetName(for: signedAmount),
            arrowSystemName: nil,
            amountText: SettlementDisplayFormatter.yen(abs(signedAmount)),
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
        .task {
            MemberPreferences.migrateLegacyValues()
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
    let arrowAssetName: String?
    let arrowSystemName: String?
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
