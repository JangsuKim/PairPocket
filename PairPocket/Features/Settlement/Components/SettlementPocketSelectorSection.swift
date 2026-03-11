import SwiftUI

struct SettlementPocketSelectorSection: View {
    @Binding var selectedPocketID: String
    let pocketOptions: [SettlementPocketOption]

    var body: some View {
        SettlementCardSection(title: "ポケット") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(pocketOptions) { option in
                        Button {
                            selectedPocketID = option.id
                        } label: {
                            Text(option.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedPocketID == option.id ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
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
