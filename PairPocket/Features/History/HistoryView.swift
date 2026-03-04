import SwiftUI

struct HistoryView: View {
    @Environment(ExpenseStore.self) private var expenseStore

    private var sortedExpenses: [Expense] {
        expenseStore.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if sortedExpenses.isEmpty {
                    Text("No expenses yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ForEach(sortedExpenses) { expense in
                        expenseRow(expense)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("履歴")
    }

    private func expenseRow(_ expense: Expense) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(expense.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(expense.memo ?? "-")
                    .font(.subheadline)
                Text("Payer: \(payerName(expense.payerRole))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatYen(expense.amount))
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func payerName(_ role: MemberRole) -> String {
        role == .me ? "A" : "B"
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
        HistoryView()
            .environment(ExpenseStore())
    }
}
