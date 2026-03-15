import Foundation

public struct SettlementSummary: Codable, Hashable {
    public var periodStart: Date
    public var periodEnd: Date
    public var totalSpent: Int
    public var totalDeposited: Int
    public var currentBalance: Int
    public var expenseCount: Int
    public var totalPaidByMemberA: Int
    public var totalPaidByMemberB: Int
    public var totalShareOfMemberA: Int
    public var totalShareOfMemberB: Int
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
        totalPaidByMemberA: Int,
        totalPaidByMemberB: Int,
        totalShareOfMemberA: Int,
        totalShareOfMemberB: Int,
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
        self.totalPaidByMemberA = totalPaidByMemberA
        self.totalPaidByMemberB = totalPaidByMemberB
        self.totalShareOfMemberA = totalShareOfMemberA
        self.totalShareOfMemberB = totalShareOfMemberB
        self.settlementPayer = settlementPayer
        self.settlementReceiver = settlementReceiver
        self.settlementAmount = settlementAmount
    }
}
