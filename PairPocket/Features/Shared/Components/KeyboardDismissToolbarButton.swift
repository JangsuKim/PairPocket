import SwiftUI

struct KeyboardDismissToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: preferredSymbolName)
                .font(.body.weight(.semibold))
        }
        .accessibilityLabel("Keyboard Dismiss")
    }

    private var preferredSymbolName: String {
        if UIImage(systemName: "keyboard.chevron.compact.down") != nil {
            return "keyboard.chevron.compact.down"
        }
        return "chevron.down.circle"
    }

}
