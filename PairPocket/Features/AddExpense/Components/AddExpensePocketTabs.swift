import SwiftUI

struct AddExpensePocketTabs: View {
    let pockets: [Pocket]
    let selectedPocket: Pocket?
    let onSelectPocket: (UUID) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(pockets) { pocket in
                    Button {
                        onSelectPocket(pocket.id)
                    } label: {
                        Text(pocket.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule().fill(
                                    selectedPocket?.id == pocket.id ? pocket.displayColor.opacity(0.2) : Color.clear
                                )
                            )
                            .foregroundStyle(selectedPocket?.id == pocket.id ? pocket.displayColor : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
}
