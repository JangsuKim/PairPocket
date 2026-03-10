import SwiftUI
import SwiftData

struct ContentView: View {
    private enum Tab: Hashable {
        case home
        case pocket
        case history
        case settlement
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var showAddExpense = false
    @State private var selectedTab: Tab = .home
    @State private var previousTab: Tab = .home
    @State private var pocketNavigationPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(Tab.home)
            .tabItem { Label("ホーム", systemImage: "house") }

            NavigationStack(path: $pocketNavigationPath) {
                PocketListView()
                    .navigationDestination(for: UUID.self) { pocketID in
                        PocketDetailView(pocketID: pocketID)
                    }
            }
            .tag(Tab.pocket)
            .tabItem { Label("ポケット", systemImage: "wallet.pass") }

            NavigationStack {
                HistoryView()
            }
            .tag(Tab.history)
            .tabItem { Label("履歴", systemImage: "clock") }

            NavigationStack {
                SettlementView()
            }
            .tag(Tab.settlement)
            .tabItem { Label("精算", systemImage: "arrow.left.arrow.right.circle") }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue == .pocket, newValue != .pocket {
                pocketNavigationPath = NavigationPath()
            }
            previousTab = newValue
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showAddExpense = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 72)
            .accessibilityLabel("追加")
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
        .task {
            try? expenseStore.loadIfNeeded(from: modelContext)
            try? pocketStore.loadIfNeeded(from: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environment(ExpenseStore())
        .environment(PocketStore())
        .modelContainer(for: [ExpenseRecord.self, PocketRecord.self], inMemory: true)
}
