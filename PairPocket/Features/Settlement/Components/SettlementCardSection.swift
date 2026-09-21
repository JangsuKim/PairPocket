import SwiftUI

struct SettlementCardSection<Content: View>: View {
    let title: String
    let cardColor: Color
    @ViewBuilder let content: Content

    init(
        title: String,
        cardColor: Color = Color("SettlementPeriwinkle"),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.cardColor = cardColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    Color(.systemBackground)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(PocketSurfaceStyle.background(for: cardColor))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PocketSurfaceStyle.border(for: cardColor), lineWidth: 0.9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
