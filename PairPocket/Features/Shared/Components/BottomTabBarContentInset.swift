import SwiftUI

enum BottomTabBarLayout {
    static let scrollContentBottomInset: CGFloat = 116
}

private struct BottomTabBarContentInsetModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.bottom, BottomTabBarLayout.scrollContentBottomInset)
    }
}

extension View {
    func bottomTabBarContentInset() -> some View {
        modifier(BottomTabBarContentInsetModifier())
    }
}
