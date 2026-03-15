import Foundation

public enum SettlementCalculator {
    public struct SummaryInput {
        public let periodStart: Date
        public let periodEnd: Date
        public let totalSpent: Int
        public let totalDeposited: Int
        public let currentBalance: Int
        public let expenseCount: Int
        public let totalPaidByMemberA: Int
        public let totalPaidByMemberB: Int
        public let totalShareOfMemberA: Int
        public let totalShareOfMemberB: Int

        public init(
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
        ) {
            self.periodStart = periodStart
            self.periodEnd = periodEnd
            self.totalSpent = totalSpent
            self.totalDeposited = totalDeposited
            self.currentBalance = currentBalance
            self.expenseCount = expenseCount
            self.totalPaidByMemberA = totalPaidByMemberA
            self.totalPaidByMemberB = totalPaidByMemberB
            self.totalShareOfMemberA = totalShareOfMemberA
            self.totalShareOfMemberB = totalShareOfMemberB
        }
    }

    public struct SettlementResult {
        public let settlementPayer: MemberRole?
        public let settlementReceiver: MemberRole?
        public let settlementAmount: Int

        public init(
            settlementPayer: MemberRole?,
            settlementReceiver: MemberRole?,
            settlementAmount: Int
        ) {
            self.settlementPayer = settlementPayer
            self.settlementReceiver = settlementReceiver
            self.settlementAmount = settlementAmount
        }
    }

    public static func calculate(input: SummaryInput) -> SettlementSummary {
        let settlement = calculateSettlement(
            totalPaidByMemberA: input.totalPaidByMemberA,
            totalPaidByMemberB: input.totalPaidByMemberB,
            totalShareOfMemberA: input.totalShareOfMemberA,
            totalShareOfMemberB: input.totalShareOfMemberB
        )

        return SettlementSummary(
            periodStart: input.periodStart,
            periodEnd: input.periodEnd,
            totalSpent: input.totalSpent,
            totalDeposited: input.totalDeposited,
            currentBalance: input.currentBalance,
            expenseCount: input.expenseCount,
            totalPaidByMemberA: input.totalPaidByMemberA,
            totalPaidByMemberB: input.totalPaidByMemberB,
            totalShareOfMemberA: input.totalShareOfMemberA,
            totalShareOfMemberB: input.totalShareOfMemberB,
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
    ) -> SettlementResult {
        let netBalanceOfMemberA = totalPaidByMemberA - totalShareOfMemberA
        let netBalanceOfMemberB = totalPaidByMemberB - totalShareOfMemberB

        if netBalanceOfMemberA > 0 {
            return SettlementResult(
                settlementPayer: .memberB,
                settlementReceiver: .memberA,
                settlementAmount: netBalanceOfMemberA
            )
        }

        if netBalanceOfMemberB > 0 {
            return SettlementResult(
                settlementPayer: .memberA,
                settlementReceiver: .memberB,
                settlementAmount: netBalanceOfMemberB
            )
        }

        return SettlementResult(
            settlementPayer: nil,
            settlementReceiver: nil,
            settlementAmount: 0
        )
    }

    public static func calculate(entries: [PocketEntry]) -> SettlementSummary {
        SettlementEngine.calculate(entries: entries)
    }

    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        SettlementEngine.calculate(expenses: expenses)
    }
}
