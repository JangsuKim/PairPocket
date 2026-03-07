import Foundation

public struct Expense: Identifiable, Codable, Hashable {
    public var id: UUID
    public var pocketId: UUID
    public var categoryId: UUID
    public var payerRole: MemberRole
    public var amount: Int
    public var ratioA: Int
    public var ratioB: Int
    public var memo: String?
    public var date: Date
    public var createdAt: Date
    public var isSettled: Bool
    public var settlementId: UUID?
    public var settledAt: Date?

    // Constraint (not enforced yet): ratioA + ratioB == 100
    public init(
        id: UUID = UUID(),
        pocketId: UUID,
        categoryId: UUID,
        payerRole: MemberRole = .a,
        amount: Int,
        ratioA: Int,
        ratioB: Int,
        memo: String? = nil,
        date: Date,
        createdAt: Date = Date(),
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.pocketId = pocketId
        self.categoryId = categoryId
        self.payerRole = payerRole
        self.amount = amount
        self.ratioA = ratioA
        self.ratioB = ratioB
        self.memo = memo
        self.date = date
        self.createdAt = createdAt
        self.isSettled = isSettled
        self.settlementId = settlementId
        self.settledAt = settledAt
    }
}
