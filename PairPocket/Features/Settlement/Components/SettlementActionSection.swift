import SwiftUI

struct SettlementActionSection: View {
    let buttonTitle: String

    var body: some View {
        Button {
        } label: {
            Text(buttonTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}
