import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    var id: UUID
    var pocketId: UUID
    var categoryId: UUID
    var amount: Int
    var date: Date
    var memo: String
    var payerRoleRaw: String
    var ratioA: Int
    var ratioB: Int
    var isSettled: Bool
    var settlementId: UUID?
    var settledAt: Date?

    var payerRole: MemberRole {
        get {
            MemberRole(rawValue: payerRoleRaw) ?? .a
        }
        set {
            payerRoleRaw = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        pocketId: UUID,
        categoryId: UUID,
        amount: Int,
        date: Date,
        memo: String = "",
        payerRoleRaw: String,
        ratioA: Int,
        ratioB: Int,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.pocketId = pocketId
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.memo = memo
        self.payerRoleRaw = payerRoleRaw
        self.ratioA = ratioA
        self.ratioB = ratioB
        self.isSettled = isSettled
        self.settlementId = settlementId
        self.settledAt = settledAt
    }

    convenience init(
        id: UUID = UUID(),
        pocketId: UUID,
        categoryId: UUID,
        amount: Int,
        date: Date,
        memo: String = "",
        payerRole: MemberRole,
        ratioA: Int,
        ratioB: Int,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.init(
            id: id,
            pocketId: pocketId,
            categoryId: categoryId,
            amount: amount,
            date: date,
            memo: memo,
            payerRoleRaw: payerRole.rawValue,
            ratioA: ratioA,
            ratioB: ratioB,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt
        )
    }
}
