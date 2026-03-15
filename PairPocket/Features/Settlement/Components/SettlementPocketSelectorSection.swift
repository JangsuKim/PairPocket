import SwiftUI

struct SettlementPocketSelectorSection: View {
    @Binding var selectedPocketID: String
    let pocketOptions: [SettlementPocketOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pocketOptions) { option in
                        PocketSelectionChip(
                            title: option.title,
                            color: option.color,
                            isSelected: selectedPocketID == option.id
                        ) {
                            selectedPocketID = option.id
                        }
                    }
                }
            }
        }
    }
}
