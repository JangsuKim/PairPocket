import Foundation

enum MemberRole: String, Codable, Hashable {
    case me
    case partner
}

struct Expense: Identifiable, Codable, Hashable {
    var id: UUID
    var pocketId: UUID
    var categoryId: UUID
    var payerRole: MemberRole
    var amount: Int
    var ratioMe: Int
    var ratioPartner: Int
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
        payerRole: MemberRole = .me,
        amount: Int,
        ratioMe: Int,
        ratioPartner: Int,
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
        self.ratioMe = ratioMe
        self.ratioPartner = ratioPartner
        self.memo = memo
        self.date = date
        self.createdAt = createdAt
        self.isSettled = isSettled
        self.settlementId = settlementId
        self.settledAt = settledAt
    }
}
