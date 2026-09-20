import Foundation
import Testing
@testable import PairPocket

struct SettlementExecutorTests {

    @Test func deletedExpensesAndDepositsAreNotSettled() {
        var deleted = makeExpense()
        deleted.isDeleted = true
        var timestampDeleted = makeExpense()
        timestampDeleted.deletedAt = Date()
        var deposit = makeExpense()
        deposit.type = .deposit
        let result = SettlementExecutor.markExpensesSettled(
            expenses: [deleted, timestampDeleted, deposit], settlementId: settlementId, settledAt: settledAt
        )
        #expect(result.allSatisfy { !$0.isSettled && $0.settlementId == nil && $0.settledAt == nil })
    }

    private let pocketId = UUID()
    private let settlementId = UUID()
    private let settledAt = Date(timeIntervalSince1970: 9999)

    private func makeExpense(isSettled: Bool = false) -> Expense {
        Expense(
            pocketId: pocketId,
            paymentSource: .host,
            amount: 1000,
            ratioHost: 50,
            ratioPartner: 50,
            date: Date(),
            isSettled: isSettled
        )
    }

    // MARK: - Empty List

    @Test func emptyList_returnsEmpty() {
        let result = SettlementExecutor.markExpensesSettled(
            expenses: [],
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result.isEmpty)
    }

    // MARK: - Unsettled Entries

    @Test func unsettledExpense_getsMarkedSettled() {
        let expense = makeExpense(isSettled: false)
        let result = SettlementExecutor.markExpensesSettled(
            expenses: [expense],
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result[0].isSettled == true)
        #expect(result[0].settlementId == settlementId)
        #expect(result[0].settledAt == settledAt)
    }

    @Test func multipleUnsettled_allGetMarked() {
        let expenses = [makeExpense(), makeExpense(), makeExpense()]
        let result = SettlementExecutor.markExpensesSettled(
            expenses: expenses,
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result.allSatisfy { $0.isSettled })
        #expect(result.allSatisfy { $0.settlementId == settlementId })
        #expect(result.allSatisfy { $0.settledAt == settledAt })
    }

    // MARK: - Already Settled Entries (Immutability)

    @Test func alreadySettled_isNotModified() {
        let originalSettlementId = UUID()
        let originalSettledAt = Date(timeIntervalSince1970: 1000)
        var expense = makeExpense(isSettled: true)
        expense.settlementId = originalSettlementId
        expense.settledAt = originalSettledAt

        let result = SettlementExecutor.markExpensesSettled(
            expenses: [expense],
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result[0].settlementId == originalSettlementId)
        #expect(result[0].settledAt == originalSettledAt)
    }

    // MARK: - Mixed

    @Test func mixedSettledAndUnsettled_onlyUnsettledAreUpdated() {
        let already = { () -> Expense in
            var exp = self.makeExpense(isSettled: true)
            exp.settlementId = UUID()
            return exp
        }()
        let pending = makeExpense(isSettled: false)

        let result = SettlementExecutor.markExpensesSettled(
            expenses: [already, pending],
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result[0].settlementId == already.settlementId)
        #expect(result[1].settlementId == settlementId)
        #expect(result[1].isSettled == true)
    }

    // MARK: - Identity Preserved

    @Test func nonSettlementFields_areUnchanged() {
        let expense = makeExpense()
        let result = SettlementExecutor.markExpensesSettled(
            expenses: [expense],
            settlementId: settlementId,
            settledAt: settledAt
        )
        #expect(result[0].id == expense.id)
        #expect(result[0].amount == expense.amount)
        #expect(result[0].paymentSource == expense.paymentSource)
    }
}
