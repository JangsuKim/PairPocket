import SwiftUI

struct PocketDetailSummary: View {
    let mode: PocketMode
    let paidByA: Int
    let paidByB: Int
    let totalAmount: Int
    let currentBalance: Int
    let formatYen: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode == .sharedManagement ? "残高サマリー" : "支出サマリー")
                .font(.headline)

            if mode == .sharedManagement {
                summaryAmountRow(title: "現在残高", amount: currentBalance, emphasized: true)
            } else {
                summaryAmountRow(title: MemberRole.host.displayName, amount: paidByA)
                summaryAmountRow(title: MemberRole.partner.displayName, amount: paidByB)

                Divider()

                summaryAmountRow(title: "合計", amount: totalAmount, emphasized: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func summaryAmountRow(title: String, amount: Int, emphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .fontWeight(emphasized ? .semibold : .regular)
            Spacer()
            Text(formatYen(amount))
                .font(emphasized ? .title3.weight(.bold) : .title3.weight(.semibold))
        }
    }
}
