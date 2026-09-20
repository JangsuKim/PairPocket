import Foundation
import Testing
@testable import PairPocket

@MainActor
struct ExpenseIdentityPolicyTests {

    private let pocketId = UUID()

    private func makeExpense(
        paymentSource: PaymentSource = .host,
        createdByUserId: String? = "user-a",
        paidByUserId: String? = "user-a"
    ) -> Expense {
        Expense(
            pocketId: pocketId,
            paymentSource: paymentSource,
            amount: 1000,
            ratioHost: 50,
            ratioPartner: 50,
            date: Date(),
            createdByUserId: createdByUserId,
            paidByUserId: paidByUserId
        )
    }

    // MARK: - Empty String Normalization

    @Test func emptyCreatedByUserId_becomesNil() {
        let expense = makeExpense(createdByUserId: "")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.createdByUserId == nil)
    }

    @Test func emptyPaidByUserId_becomesNil() {
        let expense = makeExpense(paidByUserId: "")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.paidByUserId == nil)
    }

    // MARK: - Pocket Payment Source

    @Test func pocketPaymentSource_clearsPaidByUserId() {
        let expense = makeExpense(paymentSource: .pocket, paidByUserId: "user-a")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.paidByUserId == nil)
    }

    @Test func pocketPaymentSource_preservesCreatedByUserId() {
        let expense = makeExpense(paymentSource: .pocket, createdByUserId: "user-a")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.createdByUserId == "user-a")
    }

    // MARK: - Non-Pocket Payment Source

    @Test func hostPaymentSource_keepsPaidByUserId() {
        let expense = makeExpense(paymentSource: .host, paidByUserId: "user-a")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.paidByUserId == "user-a")
    }

    @Test func partnerPaymentSource_keepsPaidByUserId() {
        let expense = makeExpense(paymentSource: .partner, paidByUserId: "user-b")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result.paidByUserId == "user-b")
    }

    // MARK: - Idempotency

    @Test func normalizedTwice_sameResult() {
        let expense = makeExpense(paymentSource: .pocket, createdByUserId: "", paidByUserId: "user-a")
        let once = ExpenseIdentityPolicy.normalized(expense)
        let twice = ExpenseIdentityPolicy.normalized(once)
        #expect(once == twice)
    }

    // MARK: - No-Op

    @Test func alreadyNormalized_unchanged() {
        let expense = makeExpense(paymentSource: .host, createdByUserId: "user-a", paidByUserId: "user-a")
        let result = ExpenseIdentityPolicy.normalized(expense)
        #expect(result == expense)
    }
}
