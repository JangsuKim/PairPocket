import SwiftUI

struct HistoryExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let expense: ExpenseRecord
    let pocketName: String
    let categoryName: String
    private let localUserId = MemberPreferences.ensureLocalUserId()
    @State private var showEditSheet = false
    @State private var shouldDismissAfterDelete = false

    private var entryTypeLabel: String {
        switch expense.entryType {
        case .expense:
            return "支出"
        case .deposit:
            return "入金"
        }
    }

    private var isExpenseEntry: Bool {
        expense.entryType == .expense
    }

    private var canEditExpense: Bool {
        isExpenseEntry && expense.isSettled == false
    }

    private var amountValueColor: Color {
        MoneyValueStyle.color(for: expense.entryType)
    }

    var body: some View {
        List {
            Section("取引情報") {
                detailRow(title: "種別", value: entryTypeLabel)
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
                detailRow(
                    title: "金額",
                    value: HistoryDetailFormatters.yen(expense.amount),
                    valueColor: amountValueColor
                )
            }

            Section("メモ") {
                Text(expense.memo.isEmpty ? "-" : expense.memo)
                    .font(.body)
            }

            if isExpenseEntry {
                Section("精算時点の情報") {
                    detailRow(title: "\(MemberRole.host.displayName)比率", value: "\(expense.ratioHost)%")
                    detailRow(title: "\(MemberRole.partner.displayName)比率", value: "\(expense.ratioPartner)%")
                    detailRow(title: "精算済み", value: expense.isSettled ? "はい" : "いいえ")
                }
            } else {
                Section("精算状態") {
                    detailRow(title: "精算済み", value: expense.isSettled ? "はい" : "いいえ")
                }
            }
        }
        .safeAreaPadding(.bottom, BottomTabBarLayout.scrollContentBottomInset)
        .navigationTitle("取引詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if canEditExpense {
                    Button {
                        showEditSheet = true
                    } label: {
                        EditButtonIcon(size: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddExpenseView(
                editingExpense: expense.pocketEntry,
                onDeleteSuccess: {
                    shouldDismissAfterDelete = true
                }
            )
        }
        .onChange(of: showEditSheet) { _, isPresented in
            guard isPresented == false, shouldDismissAfterDelete else {
                return
            }

            shouldDismissAfterDelete = false
            dismiss()
        }
    }

    private func detailRow(title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
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
