import SwiftUI

struct HistoryExpenseDetailView: View {
    let expense: ExpenseRecord
    let pocketName: String
    let categoryName: String

    var body: some View {
        List {
            Section("Expense") {
                detailRow(title: "Date", value: HistoryDetailFormatters.date.string(from: expense.date))
                detailRow(title: "Pocket", value: pocketName)
                detailRow(title: "Category", value: categoryName)
                detailRow(title: "Paid By", value: paymentSourceLabel(expense.paymentSource))
                detailRow(title: "Amount", value: HistoryDetailFormatters.yen(expense.amount))
            }

            Section("Memo") {
                Text(expense.memo.isEmpty ? "-" : expense.memo)
                    .font(.body)
            }

            Section("Settlement Snapshot") {
                detailRow(title: "Ratio A", value: "\(expense.ratioA)%")
                detailRow(title: "Ratio B", value: "\(expense.ratioB)%")
                detailRow(title: "Settled", value: expense.isSettled ? "Yes" : "No")
            }
        }
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func paymentSourceLabel(_ source: PaymentSource) -> String {
        switch source {
        case .memberA:
            return "A"
        case .memberB:
            return "B"
        case .pocket:
            return "Pocket"
        }
    }
}

private struct HistoryDetailFormatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd (EEE)"
        return formatter
    }()

    static let yenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func yen(_ amount: Int) -> String {
        let formatted = yenFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}
