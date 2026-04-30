import SwiftUI
import UIKit

struct TapToDismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

extension View {
    func tapToDismissKeyboard() -> some View {
        modifier(TapToDismissKeyboardModifier())
    }
}

