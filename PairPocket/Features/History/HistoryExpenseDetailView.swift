import SwiftUI

struct HistoryExpenseDetailView: View {
    let expense: ExpenseRecord
    let pocketName: String
    let categoryName: String
    private let localUserId = MemberPreferences.ensureLocalUserId()

    var body: some View {
        List {
            Section("支出情報") {
                detailRow(title: "日付", value: HistoryDetailFormatters.date.string(from: expense.date))
                detailRow(title: "ポケット", value: pocketName)
                detailRow(title: "カテゴリ", value: categoryName)
                detailRow(
                    title: "支払元",
                    value: MemberPreferences.payerDisplayName(
                        paymentSource: expense.paymentSource,
                        paidByUserId: expense.paidByUserId,
                        localUserId: localUserId
                    )
                )
                detailRow(title: "金額", value: HistoryDetailFormatters.yen(expense.amount))
            }

            Section("メモ") {
                Text(expense.memo.isEmpty ? "-" : expense.memo)
                    .font(.body)
            }

            Section("精算時点の情報") {
                detailRow(title: "比率 A", value: "\(expense.ratioA)%")
                detailRow(title: "比率 B", value: "\(expense.ratioB)%")
                detailRow(title: "精算済み", value: expense.isSettled ? "はい" : "いいえ")
            }
        }
        .navigationTitle("支出詳細")
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
