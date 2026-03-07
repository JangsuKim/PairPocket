import Foundation

public enum SettlementScope: String, Codable, Hashable {
    case pocket
    case total
}

public struct Settlement: Identifiable, Codable, Hashable {
    public var id: UUID
    public var scope: SettlementScope
    public var pocketId: UUID?
    public var periodStart: Date
    public var periodEnd: Date
    public var payer: MemberRole
    public var amount: Int
    public var expenseCount: Int
    public var createdAt: Date

    // periodEnd is treated as an inclusive boundary date.
    // In calculations, this is typically handled as: date < startOfDay(periodEnd + 1 day).
    public init(
        id: UUID = UUID(),
        scope: SettlementScope,
        pocketId: UUID? = nil,
        periodStart: Date,
        periodEnd: Date,
        payer: MemberRole,
        amount: Int,
        expenseCount: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scope = scope
        self.pocketId = pocketId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.payer = payer
        self.amount = amount
        self.expenseCount = expenseCount
        self.createdAt = createdAt
    }
}
