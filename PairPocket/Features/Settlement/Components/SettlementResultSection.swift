import SwiftUI

struct SettlementResultSection: View {
    let hostName: String
    let hostIcon: String
    let hostPhotoData: Data?
    let partnerName: String
    let partnerIcon: String
    let partnerPhotoData: Data?
    let arrowAssetName: String?
    let arrowSystemName: String?
    let amountText: String
    let messageText: String?
    let accentColor: Color

    var body: some View {
        SettlementCardSection(title: "精算結果") {
            VStack(spacing: 6) {
                if arrowAssetName != nil || arrowSystemName != nil {
                    SettlementDirectionSummaryRow(
                        hostName: hostName,
                        hostIcon: hostIcon,
                        hostPhotoData: hostPhotoData,
                        partnerName: partnerName,
                        partnerIcon: partnerIcon,
                        partnerPhotoData: partnerPhotoData,
                        amountText: amountText,
                        arrowAssetName: arrowAssetName,
                        arrowSystemName: arrowSystemName,
                        avatarSize: 72,
                        amountFont: .system(size: 22, weight: .bold, design: .rounded),
                        arrowWidth: 70,
                        arrowHeight: 40,
                        centerMinWidth: 96,
                        outerSpacing: 10,
                        centerSpacing: 4,
                        spacerMinLength: 8
                    )
                } else if let messageText {
                    VStack(spacing: 4) {
                        Text(amountText)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(messageText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
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
