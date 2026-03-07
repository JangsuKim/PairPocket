import SwiftUI

struct PocketListView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    @State private var isPresentingAddPocket = false
    @State private var editingPocket: Pocket?

    private var mainPocket: Pocket? {
        pocketStore.mainPocket
    }

    private var otherPockets: [Pocket] {
        pocketStore.otherPockets
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if expenseStore.expenses.isEmpty {
                    Text("まだ支出がありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let mainPocket {
                    NavigationLink {
                        PocketDetailView(pocketID: mainPocket.id)
                    } label: {
                        selectedPocketCard(pocket: mainPocket)
                    }
                    .buttonStyle(.plain)
                } else {
                    emptyMainPocketCard
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("その他のポケット")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if otherPockets.isEmpty == false {
                        stackedCardsArea
                    }

                    Button {
                        isPresentingAddPocket = true
                    } label: {
                        addPocketCard
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
            .padding()
        }
        .navigationTitle("ポケット")
        .tint(mainPocket?.displayColor ?? .accentColor)
        .sheet(isPresented: $isPresentingAddPocket) {
            NavigationStack {
                PocketFormView(mode: .add)
            }
        }
        .sheet(item: $editingPocket) { pocket in
            NavigationStack {
                PocketFormView(mode: .edit(pocket))
            }
        }
    }

    private var stackedCardsArea: some View {
        VStack(spacing: -28) {
            ForEach(Array(otherPockets.enumerated()), id: \.element.id) { index, pocket in
                smallPocketCard(pocket: pocket)
                    .zIndex(Double(otherPockets.count - index))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                            pocketStore.setMainPocket(id: pocket.id)
                        }
                    }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 10)
    }

    private func selectedPocketCard(pocket: Pocket) -> some View {
        let pocketExpenses = expenses(for: pocket.id)
        let total = pocketExpenses.reduce(0) { $0 + $1.amount }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pocket.name)
                        .font(.title3.weight(.semibold))
                    Text("メインポケット")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                }
                Spacer()
                Image(systemName: "wallet.pass.fill")
                    .font(.headline)
                    .opacity(0.9)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("今月")
                    .font(.caption)
                    .opacity(0.85)
                Text(formatYen(total))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }

            HStack {
                Text("\(pocketExpenses.count)件")
                Spacer()
                Text(pocketModeLabel(for: pocket))
            }
            .font(.subheadline)
            .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(pocket.displayColor)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func smallPocketCard(pocket: Pocket) -> some View {
        let total = expenses(for: pocket.id).reduce(0) { $0 + $1.amount }

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pocket.name)
                    .font(.headline)
                Text(formatYen(total))
                    .font(.subheadline)
                    .opacity(0.9)
                Text("\(pocket.ratioA):\(pocket.ratioB)")
                    .font(.caption)
                    .opacity(0.85)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    editingPocket = pocket
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .padding(10)
                        .background(.white.opacity(0.18))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: 10, height: 10)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(pocket.displayColor.opacity(0.92))
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
    }

    private var emptyMainPocketCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メインポケットがありません")
                .font(.headline)
            Text("ポケットを作成して始めましょう。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
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

    private func pocketModeLabel(for pocket: Pocket) -> String {
        switch (pocket.sharedBalanceEnabled, pocket.personalPaymentEnabled) {
        case (false, true):
            return "後精算"
        case (true, true):
            return "ハイブリッド"
        case (true, false):
            return "共有残高"
        case (false, false):
            return "制限あり"
        }
    }
}

#Preview {
    NavigationStack {
        PocketListView()
            .environment(ExpenseStore())
            .environment(PocketStore())
    }
}
