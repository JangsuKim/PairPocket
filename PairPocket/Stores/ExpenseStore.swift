import Foundation
import Observation

@Observable
final class ExpenseStore {
    var expenses: [Expense] = []

    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    var unsettledExpenses: [Expense] {
        expenses.filter { $0.isSettled == false }
    }
}
