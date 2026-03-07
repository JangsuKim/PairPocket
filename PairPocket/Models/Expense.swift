import Foundation

enum MemberRole: String, Codable, Hashable {
    case a
    case b
}

struct Expense: Identifiable, Codable, Hashable {
    var id: UUID
    var pocketId: UUID
    var categoryId: UUID
    var payerRole: MemberRole
    var amount: Int
    var ratioA: Int
    var ratioB: Int
    var memo: String?
    var date: Date
    var createdAt: Date
    var isSettled: Bool
    var settlementId: UUID?
    var settledAt: Date?

    init(
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
