import SwiftUI

struct SettlementResultSection: View {
    let hostName: String
    let hostIcon: String
    let partnerName: String
    let partnerIcon: String
    let arrowSystemName: String?
    let amountText: String
    let messageText: String?
    let accentColor: Color

    var body: some View {
        SettlementCardSection(title: "精算結果") {
            VStack(spacing: 6) {
                if let arrowSystemName {
                    HStack(spacing: 10) {
                        MemberProfileView(
                            role: .host,
                            name: hostName,
                            iconSystemName: hostIcon,
                            avatarSize: 56
                        )
                        Spacer(minLength: 8)
                        VStack(spacing: 4) {
                            Image(systemName: arrowSystemName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(amountText)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .frame(minWidth: 96)
                        Spacer(minLength: 8)
                        MemberProfileView(
                            role: .partner,
                            name: partnerName,
                            iconSystemName: partnerIcon,
                            avatarSize: 56
                        )
                    }
                } else if let messageText {
                    Text(messageText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(accentColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
