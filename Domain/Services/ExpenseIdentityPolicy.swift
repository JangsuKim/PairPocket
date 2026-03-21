import Foundation

public enum ExpenseIdentityPolicy {
    public static func normalized(_ expense: Expense) -> Expense {
        var normalized = expense

        if normalized.createdByUserId?.isEmpty == true {
            normalized.createdByUserId = nil
        }

        if normalized.paidByUserId?.isEmpty == true {
            normalized.paidByUserId = nil
        }

        if normalized.paymentSource.memberRole == nil {
            normalized.paidByUserId = nil
        }

        return normalized
    }
}
