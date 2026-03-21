import SwiftUI

struct SettlementActionSection: View {
    let buttonTitle: String
    let tintColor: Color

    var body: some View {
        Button {
        } label: {
            Text(buttonTitle)
                .frame(maxWidth: .infinity)
                .frame(width: 140, height: 24)
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
