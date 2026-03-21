import Foundation

public struct SettlementSummary: Codable, Hashable {
    public var periodStart: Date
    public var periodEnd: Date
    public var totalSpent: Int
    public var totalDeposited: Int
    public var currentBalance: Int
    public var expenseCount: Int
    public var totalPaidByHost: Int
    public var totalPaidByPartner: Int
    public var totalShareOfHost: Int
    public var totalShareOfPartner: Int
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
        totalPaidByHost: Int,
        totalPaidByPartner: Int,
        totalShareOfHost: Int,
        totalShareOfPartner: Int,
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
        self.totalPaidByHost = totalPaidByHost
        self.totalPaidByPartner = totalPaidByPartner
        self.totalShareOfHost = totalShareOfHost
        self.totalShareOfPartner = totalShareOfPartner
        self.settlementPayer = settlementPayer
        self.settlementReceiver = settlementReceiver
        self.settlementAmount = settlementAmount
    }
}
