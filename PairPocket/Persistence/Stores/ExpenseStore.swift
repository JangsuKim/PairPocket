import Foundation
import Observation
import SwiftData

enum ExpenseStoreError: LocalizedError {
    case expenseNotFound
    case settledExpenseDeletionBlocked
    case settledExpenseEditingBlocked
    case deletedExpenseEditingBlocked

    var errorDescription: String? {
        switch self {
        case .expenseNotFound:
            return "The expense could not be found."
        case .settledExpenseDeletionBlocked:
            return "Settled expenses cannot be deleted."
        case .settledExpenseEditingBlocked:
            return "Settled expenses cannot be edited."
        case .deletedExpenseEditingBlocked:
            return "Deleted expenses cannot be edited."
        }
    }
}

@Observable
final class ExpenseStore {
    private(set) var entries: [Transaction] = []
    private var hasLoaded = false

    var expenses: [Expense] {
        entries.filter { $0.type == .expense }
    }

    var deposits: [Transaction] {
        entries.filter { $0.type == .deposit }
    }

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
        entries = try modelContext.fetch(descriptor)
            .filter { $0.isDeleted == false }
            .map(\.pocketEntry)
    }

    func addEntry(_ entry: Transaction, in modelContext: ModelContext) throws {
        let normalizedEntry = ExpenseIdentityPolicy.normalized(entry)
        modelContext.insert(ExpenseRecord(entry: normalizedEntry))
        try modelContext.save()
        try reload(from: modelContext)
    }

    func addExpense(_ expense: Expense, in modelContext: ModelContext) throws {
        var normalizedExpense = expense
        normalizedExpense.type = .expense
        try addEntry(normalizedExpense, in: modelContext)
    }

    func updateExpense(_ expense: Expense, in modelContext: ModelContext) throws {
        let normalizedExpense = ExpenseIdentityPolicy.normalized(expense)
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate<ExpenseRecord> { record in
                record.id == normalizedExpense.id
            }
        )

        guard let record = try modelContext.fetch(descriptor).first,
              record.entryType == .expense else {
            throw ExpenseStoreError.expenseNotFound
        }

        guard record.isSettled == false else {
            throw ExpenseStoreError.settledExpenseEditingBlocked
        }
        guard record.isDeleted == false else {
            throw ExpenseStoreError.deletedExpenseEditingBlocked
        }

        record.pocketId = normalizedExpense.pocketId
        record.categoryId = normalizedExpense.categoryId
        record.amount = normalizedExpense.amount
        record.date = normalizedExpense.date
        record.memo = normalizedExpense.memo ?? ""
        record.paymentSource = normalizedExpense.paymentSource
        record.ratioHost = normalizedExpense.ratioHost
        record.ratioPartner = normalizedExpense.ratioPartner
        record.paidByUserId = normalizedExpense.paidByUserId

        try modelContext.save()
        try reload(from: modelContext)
    }

    func deleteExpense(id: UUID, in modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate<ExpenseRecord> { record in
                record.id == id
            }
        )

        guard let record = try modelContext.fetch(descriptor).first,
              record.entryType == .expense else {
            throw ExpenseStoreError.expenseNotFound
        }

        guard record.isSettled == false else {
            throw ExpenseStoreError.settledExpenseDeletionBlocked
        }

        if record.isDeleted {
            try reload(from: modelContext)
            return
        }

        record.isDeleted = true
        record.deletedAt = Date()
        try modelContext.save()
        try reload(from: modelContext)
    }

    func addDeposit(_ deposit: Transaction, in modelContext: ModelContext) throws {
        var normalizedDeposit = deposit
        normalizedDeposit.type = .deposit
        try addEntry(normalizedDeposit, in: modelContext)
    }

    func settleExpenses(
        _ expenses: [Expense],
        settlementId: UUID = UUID(),
        settledAt: Date = Date(),
        in modelContext: ModelContext
    ) throws {
        let unsettledExpenseIDs = Set(expenses.filter { $0.isSettled == false }.map(\.id))
        let settledExpenses = SettlementExecutor.markExpensesSettled(
            expenses: expenses,
            settlementId: settlementId,
            settledAt: settledAt
        )

        for expense in settledExpenses where unsettledExpenseIDs.contains(expense.id) {
            let descriptor = FetchDescriptor<ExpenseRecord>(
                predicate: #Predicate<ExpenseRecord> { record in
                    record.id == expense.id
                }
            )

            guard let record = try modelContext.fetch(descriptor).first,
                  record.entryType == .expense,
                  record.isSettled == false else {
                continue
            }

            record.isSettled = expense.isSettled
            record.settlementId = expense.settlementId
            record.settledAt = expense.settledAt
        }

        try modelContext.save()
        try reload(from: modelContext)
    }

    func entries(for pocketId: UUID) -> [Transaction] {
        entries.filter { $0.pocketId == pocketId }
    }

    func backfillIdentityFieldsIfNeeded(in modelContext: ModelContext) throws {
        // Reserved for a future migration when invite/link is implemented.
        _ = modelContext
    }

    func expenses(for pocketId: UUID) -> [Expense] {
        expenses.filter { $0.pocketId == pocketId }
    }

    func deposits(for pocketId: UUID) -> [Transaction] {
        deposits.filter { $0.pocketId == pocketId }
    }

    func currentMonthEntries(referenceDate: Date = Date()) -> [Transaction] {
        entries.filter { Calendar.current.isDate($0.date, equalTo: referenceDate, toGranularity: .month) }
    }

    var unsettledExpenses: [Expense] {
        expenses.filter { $0.isSettled == false }
    }
}
