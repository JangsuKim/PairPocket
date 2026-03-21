import Foundation

public enum SettlementCalculator {
    public struct SummaryInput {
        public let periodStart: Date
        public let periodEnd: Date
        public let totalSpent: Int
        public let totalDeposited: Int
        public let currentBalance: Int
        public let expenseCount: Int
        public let totalPaidByHost: Int
        public let totalPaidByPartner: Int
        public let totalShareOfHost: Int
        public let totalShareOfPartner: Int

        public init(
            periodStart: Date,
            periodEnd: Date,
            totalSpent: Int,
            totalDeposited: Int,
            currentBalance: Int,
            expenseCount: Int,
            totalPaidByHost: Int,
            totalPaidByPartner: Int,
            totalShareOfHost: Int,
            totalShareOfPartner: Int
        ) {
            self.periodStart = periodStart
            self.periodEnd = periodEnd
            self.totalSpent = totalSpent
            self.totalDeposited = totalDeposited
            self.currentBalance = currentBalance
            self.expenseCount = expenseCount
            self.totalPaidByHost = totalPaidByHost
            self.totalPaidByPartner = totalPaidByPartner
            self.totalShareOfHost = totalShareOfHost
            self.totalShareOfPartner = totalShareOfPartner
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
            totalPaidByHost: input.totalPaidByHost,
            totalPaidByPartner: input.totalPaidByPartner,
            totalShareOfHost: input.totalShareOfHost,
            totalShareOfPartner: input.totalShareOfPartner
        )

        return SettlementSummary(
            periodStart: input.periodStart,
            periodEnd: input.periodEnd,
            totalSpent: input.totalSpent,
            totalDeposited: input.totalDeposited,
            currentBalance: input.currentBalance,
            expenseCount: input.expenseCount,
            totalPaidByHost: input.totalPaidByHost,
            totalPaidByPartner: input.totalPaidByPartner,
            totalShareOfHost: input.totalShareOfHost,
            totalShareOfPartner: input.totalShareOfPartner,
            settlementPayer: settlement.settlementPayer,
            settlementReceiver: settlement.settlementReceiver,
            settlementAmount: settlement.settlementAmount
        )
    }

    public static func calculateSettlement(
        totalPaidByHost: Int,
        totalPaidByPartner: Int,
        totalShareOfHost: Int,
        totalShareOfPartner: Int
    ) -> SettlementResult {
        let netBalanceOfHost = totalPaidByHost - totalShareOfHost
        let netBalanceOfPartner = totalPaidByPartner - totalShareOfPartner

        if netBalanceOfHost > 0 {
            return SettlementResult(
                settlementPayer: .partner,
                settlementReceiver: .host,
                settlementAmount: netBalanceOfHost
            )
        }

        if netBalanceOfPartner > 0 {
            return SettlementResult(
                settlementPayer: .host,
                settlementReceiver: .partner,
                settlementAmount: netBalanceOfPartner
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
