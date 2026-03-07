import Foundation

public struct SettlementSummary: Codable, Hashable {
    public var periodStart: Date
    public var periodEnd: Date
    public var totalSpent: Int
    public var totalDeposited: Int
    public var currentBalance: Int
    public var expenseCount: Int
    public var totalPersonalPaidMe: Int
    public var totalPersonalPaidPartner: Int
    public var totalShouldPayA: Int
    public var totalShouldPayB: Int
    public var settlementPayer: MemberRole?
    public var settlementReceiver: MemberRole?
    public var settlementAmount: Int

    public init(
        periodStart: Date,
        periodEnd: Date,
        totalSpent: Int,
        totalDeposited: Int,
        currentBalance: Int,
        expenseCount: Int,
        totalPersonalPaidMe: Int,
        totalPersonalPaidPartner: Int,
        totalShouldPayA: Int,
        totalShouldPayB: Int,
        settlementPayer: MemberRole?,
        settlementReceiver: MemberRole?,
        settlementAmount: Int
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalSpent = totalSpent
        self.totalDeposited = totalDeposited
        self.currentBalance = currentBalance
        self.expenseCount = expenseCount
        self.totalPersonalPaidMe = totalPersonalPaidMe
        self.totalPersonalPaidPartner = totalPersonalPaidPartner
        self.totalShouldPayA = totalShouldPayA
        self.totalShouldPayB = totalShouldPayB
        self.settlementPayer = settlementPayer
        self.settlementReceiver = settlementReceiver
        self.settlementAmount = settlementAmount
    }
}

public enum SettlementCalculator {
    public static func calculate(entries: [PocketEntry]) -> SettlementSummary {
        let unsettledEntries = entries.filter { !$0.isSettled }
        let unsettledExpenses = unsettledEntries.filter { $0.type == .expense }
        let unsettledDeposits = unsettledEntries.filter { $0.type == .deposit }

        var totalSpent = 0
        var totalDeposited = 0
        var currentBalance = 0
        var totalPaidMe = 0
        var totalPaidPartner = 0
        var totalShouldPayA = 0
        var totalShouldPayB = 0

        for deposit in unsettledDeposits where deposit.paymentSource == .pocket {
            totalDeposited += deposit.amount
            currentBalance += deposit.amount
        }

        for expense in unsettledExpenses {
            totalSpent += expense.amount

            // Rounding rule (JPY Int):
            // shouldPayA = amount * ratioA / 100 (integer division, floor)
            // shouldPayB = amount - shouldPayA
            // This guarantees shouldPayA + shouldPayB == amount.
            if expense.paymentSource == .memberA || expense.paymentSource == .memberB {
                let shouldPayA = expense.amount * expense.ratioA / 100
                let shouldPayB = expense.amount - shouldPayA

                totalShouldPayA += shouldPayA
                totalShouldPayB += shouldPayB
            }

            switch expense.paymentSource {
            case .memberA:
                totalPaidMe += expense.amount
            case .memberB:
                totalPaidPartner += expense.amount
            case .pocket:
                currentBalance -= expense.amount
            }
        }

        let netMe = totalPaidMe - totalShouldPayA
        let netPartner = totalPaidPartner - totalShouldPayB

        let settlementPayer: MemberRole?
        let settlementReceiver: MemberRole?
        let settlementAmount: Int

        if netMe > 0 {
            settlementPayer = .memberB
            settlementReceiver = .memberA
            settlementAmount = netMe
        } else if netPartner > 0 {
            settlementPayer = .memberA
            settlementReceiver = .memberB
            settlementAmount = netPartner
        } else {
            settlementPayer = nil
            settlementReceiver = nil
            settlementAmount = 0
        }

        let periodStart = unsettledEntries.map(\.date).min() ?? Date.distantPast
        let periodEnd = unsettledEntries.map(\.date).max() ?? Date.distantPast

        return SettlementSummary(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalSpent: totalSpent,
            totalDeposited: totalDeposited,
            currentBalance: currentBalance,
            expenseCount: unsettledExpenses.count,
            totalPersonalPaidMe: totalPaidMe,
            totalPersonalPaidPartner: totalPaidPartner,
            totalShouldPayA: totalShouldPayA,
            totalShouldPayB: totalShouldPayB,
            settlementPayer: settlementPayer,
            settlementReceiver: settlementReceiver,
            settlementAmount: settlementAmount
        )
    }

    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        calculate(entries: expenses)
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
