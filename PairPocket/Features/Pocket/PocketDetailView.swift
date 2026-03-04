import SwiftUI

struct PocketDetailView: View {
    @Environment(ExpenseStore.self) private var expenseStore

    let pocket: PocketItem

    private var pocketExpenses: [Expense] {
        expenseStore.expenses
            .filter { $0.pocketId == pocket.id }
            .sorted { $0.date > $1.date }
    }

    private var totalAmount: Int {
        pocketExpenses.reduce(0) { $0 + $1.amount }
    }

    private var paidByMe: Int {
        pocketExpenses
            .filter { $0.payerRole == .me }
            .reduce(0) { $0 + $1.amount }
    }

    private var paidByPartner: Int {
        pocketExpenses
            .filter { $0.payerRole == .partner }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summarySection

                if pocketExpenses.isEmpty {
                    Text("No expenses yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Expenses")
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
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Summary")
                .font(.headline)

            summaryRow(title: "Person A", amount: paidByMe)
            summaryRow(title: "Person B", amount: paidByPartner)

            Divider()

            summaryRow(title: "Total", amount: totalAmount, isEmphasized: true)
        }
        .padding(16)
        .background(.thinMaterial)
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
        PocketDetailView(pocket: .init(id: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!, name: "生活費", color: .green))
            .environment(ExpenseStore())
    }
}
