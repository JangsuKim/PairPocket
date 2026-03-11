import SwiftUI
import SwiftData

struct ContentView: View {
    enum ContentTab: Hashable {
        case home
        case pocket
        case history
        case settlement
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var showAddExpense = false
    @State private var selectedTab: ContentTab = .home
    @State private var previousTab: ContentTab = .home
    @State private var pocketNavigationPath = NavigationPath()

    var body: some View {
        ZStack {
            tabContainer(for: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            tabContainer(for: .pocket) {
                NavigationStack(path: $pocketNavigationPath) {
                    PocketListView()
                        .navigationDestination(for: UUID.self) { pocketID in
                            PocketDetailView(pocketID: pocketID)
                        }
                }
            }

            tabContainer(for: .history) {
                NavigationStack {
                    HistoryView()
                }
            }

            tabContainer(for: .settlement) {
                NavigationStack {
                    SettlementView()
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == .pocket, newValue != .pocket {
                pocketNavigationPath = NavigationPath()
            }
            previousTab = newValue
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(
                selectedTab: $selectedTab,
                showAddExpense: $showAddExpense
            )
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
        .task {
            try? expenseStore.loadIfNeeded(from: modelContext)
            try? pocketStore.loadIfNeeded(from: modelContext)
        }
    }

    private func tabContainer<Content: View>(
        for tab: ContentTab,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .zIndex(selectedTab == tab ? 1 : 0)
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
        .environment(PocketStore())
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self], inMemory: true)
}
