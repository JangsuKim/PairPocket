import SwiftUI

struct PocketDetailView: View {
    @Environment(ExpenseStore.self) private var expenseStore
    @Environment(PocketStore.self) private var pocketStore

    let pocketID: UUID

    @State private var editingPocket: Pocket?

    private var pocket: Pocket? {
        pocketStore.pocket(for: pocketID)
    }

    private var pocketExpenses: [Expense] {
        guard let pocket else {
            return []
        }

        return expenseStore.expenses
            .filter { $0.pocketId == pocket.id }
            .sorted { $0.date > $1.date }
    }

    private var totalAmount: Int {
        pocketExpenses.reduce(0) { $0 + $1.amount }
    }

    private var paidByA: Int {
        pocketExpenses
            .filter { $0.paymentSource == .memberA }
            .reduce(0) { $0 + $1.amount }
    }

    private var paidByB: Int {
        pocketExpenses
            .filter { $0.paymentSource == .memberB }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if let pocket {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summarySection
                        pocketInfoSection(for: pocket)

                        if pocketExpenses.isEmpty {
                            Text("まだ支出がありません")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("支出一覧")
                                    .font(.headline)

                                ForEach(pocketExpenses) { expense in
                                    expenseRow(expense)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle(pocket.name)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if pocket.isMain == false {
                            Button("メインに設定") {
                                pocketStore.setMainPocket(id: pocket.id)
                            }
                        }

                        Button("編集") {
                            editingPocket = pocket
                        }
                    }
                }
            } else {
                ContentUnavailableView("ポケットが見つかりません", systemImage: "wallet.pass")
                    .navigationTitle("ポケット")
            }
        }
        .sheet(item: $editingPocket) { pocket in
            NavigationStack {
                PocketFormView(mode: .edit(pocket))
            }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("支払いサマリー")
                .font(.headline)

            summaryRow(title: "Aの支払い", amount: paidByA)
            summaryRow(title: "Bの支払い", amount: paidByB)

            Divider()

            summaryRow(title: "合計", amount: totalAmount, isEmphasized: true)
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func pocketInfoSection(for pocket: Pocket) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ポケット設定")
                .font(.headline)

            detailRow(title: "比率", value: "\(pocket.ratioA)% / \(pocket.ratioB)%")
            detailRow(title: "共有残高", value: pocket.sharedBalanceEnabled ? "オン" : "オフ")
            detailRow(title: "個人支払い", value: pocket.personalPaymentEnabled ? "オン" : "オフ")
            detailRow(title: "メインポケット", value: pocket.isMain ? "はい" : "いいえ")
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(expense.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(expense.memo ?? "-")
                    .font(.subheadline)
            }

            Spacer()

            Text(formatYen(expense.amount))
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func summaryRow(title: String, amount: Int, isEmphasized: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatYen(amount))
                .fontWeight(isEmphasized ? .bold : .regular)
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
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
        PocketDetailView(
            pocketID: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!
        )
        .environment(ExpenseStore())
        .environment(PocketStore())
    }
}
