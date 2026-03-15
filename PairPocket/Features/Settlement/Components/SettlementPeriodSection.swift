import SwiftUI

struct SettlementPeriodSection: View {
    let periodText: String
    let durationText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Text(periodText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(durationText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
