import SwiftUI

struct PocketListView: View {
    private let pockets: [Pocket] = [
        .init(id: 0, name: "Total", amountYen: 146_624, count: 12),
        .init(id: 1, name: "Living", amountYen: 84_360, count: 7),
        .init(id: 2, name: "Travel", amountYen: 26_800, count: 2),
        .init(id: 3, name: "Rent", amountYen: 78_000, count: 1),
    ]

    var body: some View {
        List(pockets) { pocket in
            NavigationLink {
                PocketDetailView(pocket: pocket)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pocket.name)
                            .font(.headline)
                        Text("This month: \(pocket.count) transactions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(formatYen(pocket.amountYen))
                        .font(.headline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Pocket")
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}

#Preview {
    NavigationStack {
        PocketListView()
    }
}
