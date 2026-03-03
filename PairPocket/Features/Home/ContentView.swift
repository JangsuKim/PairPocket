import SwiftUI

struct ContentView: View {
    @State private var showAddExpense = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house") }

            NavigationStack {
                PocketListView()
            }
            .tabItem { Label("Pocket", systemImage: "wallet.pass") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
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
            .accessibilityLabel("Add")
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView()
        }
    }
}

#Preview {
    ContentView()
}
