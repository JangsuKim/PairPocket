import Foundation

public enum SettlementInterpretationBoundary {
    // Current rule: settlement math is role-based.
    // Future rule: payer identity (userId) can be mapped to role via RelationshipContext.

    public static func rolePaymentSource(for expense: Expense) -> PaymentSource {
        expense.paymentSource
    }

    public static func payerIdentity(for expense: Expense) -> String? {
        expense.paidByUserId
    }
}
