import SwiftUI

struct PocketListView: View {
    @Environment(ExpenseStore.self) private var expenseStore

    private let isProUser = false

    @State private var selectedPocketID: UUID = PocketCatalog.pockets[0].id

    private var pockets: [PocketItem] {
        PocketCatalog.pockets
    }

    private var selectedPocket: PocketItem {
        pockets.first(where: { $0.id == selectedPocketID }) ?? pockets[0]
    }

    private var remainingPockets: [PocketItem] {
        pockets.filter { $0.id != selectedPocket.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if expenseStore.expenses.isEmpty {
                    Text("No expenses yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    PocketDetailView(pocket: selectedPocket)
                } label: {
                    selectedPocketCard(pocket: selectedPocket)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Other Pockets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !remainingPockets.isEmpty {
                        stackedCardsArea
                    }

                    addPocketCard
                        .onTapGesture {
                            print("add pocket tapped")
                        }
                        .padding(.top, 6)
                }
            }
            .padding()
        }
        .navigationTitle("ポケット")
        .tint(selectedPocket.color)
    }

    private var stackedCardsArea: some View {
        VStack(spacing: -28) {
            ForEach(Array(remainingPockets.enumerated()), id: \.element.id) { index, pocket in
                smallPocketCard(pocket: pocket)
                    .zIndex(Double(remainingPockets.count - index))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            selectedPocketID = pocket.id
                        }
                    }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func selectedPocketCard(pocket: PocketItem) -> some View {
        let pocketExpenses = expenses(for: pocket.id)
        let total = pocketExpenses.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(pocket.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .font(.headline)
                    .opacity(0.9)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("This month")
                    .font(.caption)
                    .opacity(0.85)
                Text(formatYen(total))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }

            HStack {
                Text("\(pocketExpenses.count) tx")
                Spacer()
                Text(pocketModeLabel(for: pocket))
            }
            .font(.subheadline)
            .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(pocket.color)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func smallPocketCard(pocket: PocketItem) -> some View {
        let total = expenses(for: pocket.id).reduce(0) { $0 + $1.amount }

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pocket.name)
                    .font(.headline)
                Text(formatYen(total))
                    .font(.subheadline)
                    .opacity(0.9)
            }
            Spacer()
            Circle()
                .fill(.white.opacity(0.9))
                .frame(width: 10, height: 10)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(pocket.color.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var addPocketCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.subheadline.weight(.bold))
            Text("ポケットを追加")
                .font(.headline)
            Spacer()
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(.tertiary)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .opacity(isProUser ? 0 : 1)
    }

    private func expenses(for pocketId: UUID) -> [Expense] {
        expenseStore.expenses.filter { $0.pocketId == pocketId }
    }

    private func formatYen(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }

    private func pocketModeLabel(for pocket: PocketItem) -> String {
        switch (pocket.sharedBalanceEnabled, pocket.personalPaymentEnabled) {
        case (false, true):
            return "post-settlement"
        case (true, true):
            return "hybrid"
        case (true, false):
            return "shared-balance"
        case (false, false):
            return "restricted"
        }
    }
}

struct PocketItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: Color
    let sharedBalanceEnabled: Bool
    let personalPaymentEnabled: Bool
}

private enum PocketCatalog {
    static let pockets: [PocketItem] = [
        .init(
            id: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "生活費",
            color: .green,
            sharedBalanceEnabled: false,
            personalPaymentEnabled: true
        ),
        .init(
            id: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "旅行",
            color: .orange,
            sharedBalanceEnabled: true,
            personalPaymentEnabled: true
        ),
        .init(
            id: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "住居",
            color: .purple,
            sharedBalanceEnabled: true,
            personalPaymentEnabled: false
        ),
    ]
}

#Preview {
    NavigationStack {
        PocketListView()
            .environment(ExpenseStore())
    }
}
