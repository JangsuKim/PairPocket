import SwiftUI

struct SettlementPeriodSection: View {
    let periodText: String

    var body: some View {
        SettlementCardSection(title: "精算期間") {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(periodText)
                    .font(.subheadline.weight(.medium))

                Spacer()
            }
        }
    }
}
