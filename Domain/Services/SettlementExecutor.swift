import Foundation

public enum SettlementExecutor {
    public static func markExpensesSettled(
        expenses: [Expense],
        settlementId: UUID,
        settledAt: Date
    ) -> [Expense] {
        expenses.map { expense in
            guard expense.isSettled == false else {
                return expense
            }

            var updated = expense
            updated.isSettled = true
            updated.settlementId = settlementId
            updated.settledAt = settledAt
            return updated
        }
    }
}
