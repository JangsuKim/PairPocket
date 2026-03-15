import SwiftUI

struct SettlementActionSection: View {
    let buttonTitle: String

    var body: some View {
        Button {
        } label: {
            Text(buttonTitle)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
