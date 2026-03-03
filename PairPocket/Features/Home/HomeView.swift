import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MonthlySummarySection()
                QuickAddSection()
                SettlementSection()
            }
            .padding()
        }
        .navigationTitle("ペアポケ")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
