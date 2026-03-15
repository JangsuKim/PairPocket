import SwiftUI

struct SettlementResultSection: View {
    let fromMemberName: String
    let toMemberName: String
    let amountText: String

    var body: some View {
        SettlementCardSection(title: "精算結果") {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    resultBadge(title: fromMemberName)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    resultBadge(title: toMemberName)
                }

                Text(amountText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func resultBadge(title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(Capsule())
    }
}
