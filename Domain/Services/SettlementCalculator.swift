import Foundation

public enum SettlementCalculator {
    public static func calculate(
        periodStart: Date,
        periodEnd: Date,
        totalSpent: Int,
        totalDeposited: Int,
        currentBalance: Int,
        expenseCount: Int,
        totalPaidByMemberA: Int,
        totalPaidByMemberB: Int,
        totalShareOfMemberA: Int,
        totalShareOfMemberB: Int
    ) -> SettlementSummary {
        let settlement = calculateSettlement(
            totalPaidByMemberA: totalPaidByMemberA,
            totalPaidByMemberB: totalPaidByMemberB,
            totalShareOfMemberA: totalShareOfMemberA,
            totalShareOfMemberB: totalShareOfMemberB
        )

        return SettlementSummary(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalSpent: totalSpent,
            totalDeposited: totalDeposited,
            currentBalance: currentBalance,
            expenseCount: expenseCount,
            totalPaidByMemberA: totalPaidByMemberA,
            totalPaidByMemberB: totalPaidByMemberB,
            totalShareOfMemberA: totalShareOfMemberA,
            totalShareOfMemberB: totalShareOfMemberB,
            settlementPayer: settlement.settlementPayer,
            settlementReceiver: settlement.settlementReceiver,
            settlementAmount: settlement.settlementAmount
        )
    }

    public static func calculateSettlement(
        totalPaidByMemberA: Int,
        totalPaidByMemberB: Int,
        totalShareOfMemberA: Int,
        totalShareOfMemberB: Int
    ) -> (
        settlementPayer: MemberRole?,
        settlementReceiver: MemberRole?,
        settlementAmount: Int
    ) {
        let netBalanceOfMemberA = totalPaidByMemberA - totalShareOfMemberA
        let netBalanceOfMemberB = totalPaidByMemberB - totalShareOfMemberB

        if netBalanceOfMemberA > 0 {
            return (.memberB, .memberA, netBalanceOfMemberA)
        }

        if netBalanceOfMemberB > 0 {
            return (.memberA, .memberB, netBalanceOfMemberB)
        }

        return (nil, nil, 0)
    }

    public static func calculate(entries: [PocketEntry]) -> SettlementSummary {
        SettlementEngine.calculate(entries: entries)
    }

    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        SettlementEngine.calculate(expenses: expenses)
    }
}
