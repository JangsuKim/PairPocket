import SwiftUI

struct PocketDetailSettlement: View {
    let payerName: String?
    let receiverName: String?
    let settlementAmount: Int
    let formatYen: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精算予定")
                .font(.headline)

            Text("現在の精算予定額")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let payerName,
               let receiverName,
               settlementAmount > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(payerName) → \(receiverName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(formatYen(settlementAmount))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
            } else {
                Text("精算なし")
                    .font(.title3.weight(.bold))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

