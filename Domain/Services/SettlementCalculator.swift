import Foundation

public struct SettlementSummary: Codable, Hashable {
    public var periodStart: Date
    public var periodEnd: Date
    public var totalAmount: Int
    public var expenseCount: Int
    public var totalPaidA: Int
    public var totalPaidB: Int
    public var totalShouldPayA: Int
    public var totalShouldPayB: Int
    public var settlementPayer: MemberRole?
    public var settlementReceiver: MemberRole?
    public var settlementAmount: Int

    public init(
        periodStart: Date,
        periodEnd: Date,
        totalAmount: Int,
        expenseCount: Int,
        totalPaidA: Int,
        totalPaidB: Int,
        totalShouldPayA: Int,
        totalShouldPayB: Int,
        settlementPayer: MemberRole?,
        settlementReceiver: MemberRole?,
        settlementAmount: Int
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalAmount = totalAmount
        self.expenseCount = expenseCount
        self.totalPaidA = totalPaidA
        self.totalPaidB = totalPaidB
        self.totalShouldPayA = totalShouldPayA
        self.totalShouldPayB = totalShouldPayB
        self.settlementPayer = settlementPayer
        self.settlementReceiver = settlementReceiver
        self.settlementAmount = settlementAmount
    }
}

public enum SettlementCalculator {
    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        let unsettledExpenses = expenses.filter { !$0.isSettled }

        var totalAmount = 0
        var totalPaidA = 0
        var totalPaidB = 0
        var totalShouldPayA = 0
        var totalShouldPayB = 0

        for expense in unsettledExpenses {
            totalAmount += expense.amount

            // Rounding rule (JPY Int):
            // shouldPayA = amount * ratioA / 100 (integer division, floor)
            // shouldPayB = amount - shouldPayA
            // This guarantees shouldPayA + shouldPayB == amount.
            let shouldPayA = expense.amount * expense.ratioA / 100
            let shouldPayB = expense.amount - shouldPayA

            totalShouldPayA += shouldPayA
            totalShouldPayB += shouldPayB

            if expense.payerRole == .a {
                totalPaidA += expense.amount
            } else {
                totalPaidB += expense.amount
            }
        }

        let netA = totalPaidA - totalShouldPayA
        let netB = totalPaidB - totalShouldPayB

        let settlementPayer: MemberRole?
        let settlementReceiver: MemberRole?
        let settlementAmount: Int

        if netA > 0 {
            settlementPayer = .b
            settlementReceiver = .a
            settlementAmount = netA
        } else if netB > 0 {
            settlementPayer = .a
            settlementReceiver = .b
            settlementAmount = netB
        } else {
            settlementPayer = nil
            settlementReceiver = nil
            settlementAmount = 0
        }

        let periodStart = unsettledExpenses.map(\.date).min() ?? Date.distantPast
        let periodEnd = unsettledExpenses.map(\.date).max() ?? Date.distantPast

        return SettlementSummary(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalAmount: totalAmount,
            expenseCount: unsettledExpenses.count,
            totalPaidA: totalPaidA,
            totalPaidB: totalPaidB,
            totalShouldPayA: totalShouldPayA,
            totalShouldPayB: totalShouldPayB,
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
