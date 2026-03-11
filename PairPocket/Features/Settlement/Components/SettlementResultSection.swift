import SwiftUI

struct SettlementResultSection: View {
    let fromMemberName: String
    let toMemberName: String
    let amountText: String

    var body: some View {
        SettlementCardSection(title: "精算結果") {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    resultBadge(title: fromMemberName)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    resultBadge(title: toMemberName)
                }

                Text(amountText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func resultBadge(title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}
