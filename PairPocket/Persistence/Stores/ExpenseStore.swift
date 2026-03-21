import Foundation
import Observation
import SwiftData

@Observable
final class ExpenseStore {
    private(set) var expenses: [Expense] = []
    private var hasLoaded = false

    func loadIfNeeded(from modelContext: ModelContext) throws {
        guard hasLoaded == false else {
            return
        }

        try reload(from: modelContext)
        hasLoaded = true
    }

    func reload(from modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<ExpenseRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        expenses = try modelContext.fetch(descriptor).map(\.pocketEntry)
    }

    func addExpense(_ expense: Expense, in modelContext: ModelContext) throws {
        let normalizedExpense = ExpenseIdentityPolicy.normalized(expense)
        modelContext.insert(ExpenseRecord(entry: normalizedExpense))
        try modelContext.save()
        try reload(from: modelContext)
    }

    func backfillIdentityFieldsIfNeeded(in modelContext: ModelContext) throws {
        // Reserved for a future migration when invite/link is implemented.
        _ = modelContext
    }

    func expenses(for pocketId: UUID) -> [Expense] {
        expenses.filter { $0.pocketId == pocketId }
    }

    func currentMonthExpenses(referenceDate: Date = Date()) -> [Expense] {
        expenses.filter { Calendar.current.isDate($0.date, equalTo: referenceDate, toGranularity: .month) }
    }

    var unsettledExpenses: [Expense] {
        expenses.filter { $0.isSettled == false }
    }
}
