import SwiftUI

struct EditButtonIcon: View {
    let size: CGFloat

    var body: some View {
        Image("EditButtonIcon")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}
