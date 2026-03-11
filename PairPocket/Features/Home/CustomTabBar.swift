import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.ContentTab
    @Binding var showAddExpense: Bool
    @Namespace private var tabGlassNamespace

    private let items: [TabBarItem] = [
        TabBarItem(tab: .home, title: "ホーム", systemImage: "house"),
        TabBarItem(tab: .pocket, title: "ポケット", systemImage: "wallet.pass"),
        TabBarItem(tab: .history, title: "履歴", systemImage: "clock"),
        TabBarItem(tab: .settlement, title: "精算", systemImage: "arrow.left.arrow.right.circle")
    ]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            tabGroup

            Button {
                showAddExpense = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 60, height: 60)
                    .addButtonGlassBackground()
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("追加")
            .offset(y: -2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(.clear)
                .background(.thinMaterial)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }

    private var tabGroup: some View {
        tabGroupContent
    }

    private var tabGroupContent: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                tabButton(for: item)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .tabGroupGlassBackground()
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func tabButton(for item: TabBarItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedTab = item.tab
            }
        } label: {
            ZStack {
                if selectedTab == item.tab {
                    selectedTabBackground
                }

                VStack(spacing: 4) {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 18, weight: selectedTab == item.tab ? .semibold : .regular))
                    Text(item.title)
                        .font(.caption2.weight(selectedTab == item.tab ? .semibold : .regular))
                }
                .foregroundStyle(selectedTab == item.tab ? Color.accentColor : Color.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedTabBackground: some View {
        if #available(iOS 26.0, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular.interactive(), in: Capsule())
                .matchedGeometryEffect(id: "selected-tab", in: tabGlassNamespace)
                .padding(.horizontal, 2)
        } else {
            Capsule()
                .fill(Color.white.opacity(0.72))
                .matchedGeometryEffect(id: "selected-tab", in: tabGlassNamespace)
                .padding(.horizontal, 2)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
    }
}

private struct TabGroupGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                }
        }
    }
}

private struct AddButtonGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                }
        }
    }
}

private extension View {
    func tabGroupGlassBackground() -> some View {
        modifier(TabGroupGlassBackground())
    }

    func addButtonGlassBackground() -> some View {
        modifier(AddButtonGlassBackground())
    }
}

private struct TabBarItem: Identifiable {
    let tab: ContentView.ContentTab
    let title: String
    let systemImage: String

    var id: ContentView.ContentTab { tab }
}
