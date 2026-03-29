import SwiftUI
import SwiftData

struct HistoryExpenseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ExpenseStore.self) private var expenseStore

    let expense: ExpenseRecord
    let pocketName: String
    let categoryName: String
    private let localUserId = MemberPreferences.ensureLocalUserId()
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

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

    private var canDeleteExpense: Bool {
        isExpenseEntry && expense.isSettled == false
    }

    private var canEditExpense: Bool {
        isExpenseEntry && expense.isSettled == false
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
                detailRow(title: "金額", value: HistoryDetailFormatters.yen(expense.amount))
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

                Section("編集") {
                    if canEditExpense {
                        Button("支出を編集") {
                            showEditSheet = true
                        }
                    } else {
                        Text("Settled expenses cannot be edited.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("削除") {
                    if canDeleteExpense {
                        Button("支出を削除", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    } else {
                        Text("Settled expenses cannot be deleted.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
        .confirmationDialog(
            "Delete this expense?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                deleteExpense()
            }
            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Delete Failed", isPresented: deleteErrorAlertBinding) {
            Button("OK", role: .cancel) {
                deleteErrorMessage = nil
            }
        } message: {
            Text(deleteErrorMessage ?? "Unknown error.")
        }
        .sheet(isPresented: $showEditSheet) {
            AddExpenseView(editingExpense: expense.pocketEntry)
        }
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

    private func deleteExpense() {
        do {
            try expenseStore.deleteExpense(id: expense.id, in: modelContext)
            dismiss()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }

    private var deleteErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if isPresented == false {
                    deleteErrorMessage = nil
                }
            }
        )
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
