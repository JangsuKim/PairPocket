import SwiftUI

struct SettlementPocketSelectorSection: View {
    @Binding var selectedPocketID: String
    let pocketOptions: [SettlementPocketOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ポケット")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pocketOptions) { option in
                        Button {
                            selectedPocketID = option.id
                        } label: {
                            Text(option.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedPocketID == option.id ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedPocketID == option.id ? Color.accentColor : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
