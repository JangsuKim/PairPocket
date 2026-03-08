import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var showAddExpense = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("ホーム", systemImage: "house") }

            NavigationStack {
                PocketListView()
            }
            .tabItem { Label("ポケット", systemImage: "wallet.pass") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("履歴", systemImage: "clock") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("設定", systemImage: "gearshape") }
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
