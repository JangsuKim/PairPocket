import Foundation

public struct SettlementSummary: Codable, Hashable {
    public var periodStart: Date
    public var periodEnd: Date
    public var totalAmount: Int
    public var expenseCount: Int
    public var totalPaidMe: Int
    public var totalPaidPartner: Int
    public var totalShouldPayMe: Int
    public var totalShouldPayPartner: Int
    public var settlementPayer: MemberRole?
    public var settlementReceiver: MemberRole?
    public var settlementAmount: Int

    public init(
        periodStart: Date,
        periodEnd: Date,
        totalAmount: Int,
        expenseCount: Int,
        totalPaidMe: Int,
        totalPaidPartner: Int,
        totalShouldPayMe: Int,
        totalShouldPayPartner: Int,
        settlementPayer: MemberRole?,
        settlementReceiver: MemberRole?,
        settlementAmount: Int
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalAmount = totalAmount
        self.expenseCount = expenseCount
        self.totalPaidMe = totalPaidMe
        self.totalPaidPartner = totalPaidPartner
        self.totalShouldPayMe = totalShouldPayMe
        self.totalShouldPayPartner = totalShouldPayPartner
        self.settlementPayer = settlementPayer
        self.settlementReceiver = settlementReceiver
        self.settlementAmount = settlementAmount
    }
}

public enum SettlementCalculator {
    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        let unsettledExpenses = expenses.filter { !$0.isSettled }

        var totalAmount = 0
        var totalPaidMe = 0
        var totalPaidPartner = 0
        var totalShouldPayMe = 0
        var totalShouldPayPartner = 0

        for expense in unsettledExpenses {
            totalAmount += expense.amount

            // Rounding rule (JPY Int):
            // shouldPayMe = amount * ratioMe / 100 (integer division, floor)
            // shouldPayPartner = amount - shouldPayMe
            // This guarantees shouldPayMe + shouldPayPartner == amount.
            let shouldPayMe = expense.amount * expense.ratioMe / 100
            let shouldPayPartner = expense.amount - shouldPayMe

            totalShouldPayMe += shouldPayMe
            totalShouldPayPartner += shouldPayPartner

            if expense.payerRole == .me {
                totalPaidMe += expense.amount
            } else {
                totalPaidPartner += expense.amount
            }
        }

        let netMe = totalPaidMe - totalShouldPayMe
        let netPartner = totalPaidPartner - totalShouldPayPartner

        let settlementPayer: MemberRole?
        let settlementReceiver: MemberRole?
        let settlementAmount: Int

        if netMe > 0 {
            settlementPayer = .partner
            settlementReceiver = .me
            settlementAmount = netMe
        } else if netPartner > 0 {
            settlementPayer = .me
            settlementReceiver = .partner
            settlementAmount = netPartner
        } else {
            settlementPayer = nil
            settlementReceiver = nil
            settlementAmount = 0
        }

        // Settlement logic does not depend on expense dates.
        // periodStart/periodEnd are derived only for summary display.
        let periodStart = unsettledExpenses.map(\.date).min() ?? Date.distantPast
        let periodEnd = unsettledExpenses.map(\.date).max() ?? Date.distantPast

        return SettlementSummary(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalAmount: totalAmount,
            expenseCount: unsettledExpenses.count,
            totalPaidMe: totalPaidMe,
            totalPaidPartner: totalPaidPartner,
            totalShouldPayMe: totalShouldPayMe,
            totalShouldPayPartner: totalShouldPayPartner,
            settlementPayer: settlementPayer,
            settlementReceiver: settlementReceiver,
            settlementAmount: settlementAmount
        )
    }

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
