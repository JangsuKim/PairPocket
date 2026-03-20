import SwiftUI

struct SettlementResultSection: View {
    let fromMemberRole: MemberRole?
    let fromMemberName: String?
    let fromMemberIcon: String?
    let toMemberRole: MemberRole?
    let toMemberName: String?
    let toMemberIcon: String?
    let amountText: String
    let messageText: String?
    let accentColor: Color

    var body: some View {
        SettlementCardSection(title: "精算結果") {
            VStack(spacing: 6) {
                if let fromMemberRole,
                   let fromMemberName,
                   let fromMemberIcon,
                   let toMemberRole,
                   let toMemberName,
                   let toMemberIcon {
                    HStack(spacing: 10) {
                        MemberProfileView(
                            role: fromMemberRole,
                            name: fromMemberName,
                            iconSystemName: fromMemberIcon,
                            avatarSize: 56
                        )
                        Spacer(minLength: 8)
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.right")
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
                            role: toMemberRole,
                            name: toMemberName,
                            iconSystemName: toMemberIcon,
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
