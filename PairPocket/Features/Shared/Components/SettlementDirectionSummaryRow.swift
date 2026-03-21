import SwiftUI

struct SettlementDirectionSummaryRow: View {
    let hostName: String
    let hostIcon: String
    let hostPhotoData: Data?
    let partnerName: String
    let partnerIcon: String
    let partnerPhotoData: Data?
    let amountText: String
    let arrowAssetName: String?
    let arrowSystemName: String?
    var avatarSize: CGFloat = 56
    var amountFont: Font = .system(size: 22, weight: .bold, design: .rounded)
    var arrowWidth: CGFloat = 28
    var arrowHeight: CGFloat = 16
    var centerMinWidth: CGFloat = 96
    var outerSpacing: CGFloat = 10
    var centerSpacing: CGFloat = 4
    var spacerMinLength: CGFloat = 8

    var body: some View {
        HStack(spacing: outerSpacing) {
            MemberProfileView(
                role: .host,
                name: hostName,
                iconSystemName: hostIcon,
                photoData: hostPhotoData,
                avatarSize: avatarSize
            )
            Spacer(minLength: spacerMinLength)
            VStack(spacing: centerSpacing) {
                if let arrowAssetName {
                    Image(arrowAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: arrowWidth, height: arrowHeight)
                } else if let arrowSystemName {
                    Image(systemName: arrowSystemName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(amountText)
                    .font(amountFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(minWidth: centerMinWidth)
            Spacer(minLength: spacerMinLength)
            MemberProfileView(
                role: .partner,
                name: partnerName,
                iconSystemName: partnerIcon,
                photoData: partnerPhotoData,
                avatarSize: avatarSize
            )
        }
    }
}
