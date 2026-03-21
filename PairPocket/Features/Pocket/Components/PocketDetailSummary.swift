import SwiftUI

struct PocketDetailSummary: View {
    let paidByA: Int
    let paidByB: Int
    let totalAmount: Int
    let formatYen: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("支出サマリー")
                .font(.headline)

            summaryAmountRow(title: MemberRole.host.displayName, amount: paidByA)
            summaryAmountRow(title: MemberRole.partner.displayName, amount: paidByB)

            Divider()

            summaryAmountRow(title: "合計", amount: totalAmount, emphasized: true)
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
