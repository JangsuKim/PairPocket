import SwiftUI

struct SettlementSection: View {
    private let leftName = "A"
    private let rightName = "B"
    private let amountText = "¥32,123"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("精算")
                .font(.headline)

            HStack(spacing: 12) {
                UserChip(name: leftName)
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    Text(amountText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("→")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                UserChip(name: rightName)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                // TODO: 精算依頼
            } label: {
                Text("精算を依頼")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    SettlementSection()
}
