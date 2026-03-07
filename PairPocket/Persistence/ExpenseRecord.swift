import Foundation
import SwiftData

@Model
final class ExpenseRecord {
    var id: UUID
    var pocketId: UUID
    var entryTypeRaw: String
    var categoryId: UUID?
    var amount: Int
    var date: Date
    var memo: String
    var paymentSourceRaw: String
    var ratioA: Int
    var ratioB: Int
    var isSettled: Bool
    var settlementId: UUID?
    var settledAt: Date?

    var entryType: PocketEntryType {
        get {
            PocketEntryType(rawValue: entryTypeRaw) ?? .expense
        }
        set {
            entryTypeRaw = newValue.rawValue
        }
    }

    var paymentSource: PaymentSource {
        get {
            PaymentSource(storageValue: paymentSourceRaw)
        }
        set {
            paymentSourceRaw = newValue.rawValue
        }
    }

    var payerRole: MemberRole {
        get {
            paymentSource.payerRole ?? .memberA
        }
        set {
            paymentSource = newValue == .memberA ? .memberA : .memberB
        }
    }

    init(
        id: UUID = UUID(),
        pocketId: UUID,
        entryTypeRaw: String = PocketEntryType.expense.rawValue,
        categoryId: UUID? = nil,
        amount: Int,
        date: Date,
        memo: String = "",
        paymentSourceRaw: String,
        ratioA: Int,
        ratioB: Int,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.pocketId = pocketId
        self.entryTypeRaw = entryTypeRaw
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.memo = memo
        self.paymentSourceRaw = paymentSourceRaw
        self.ratioA = ratioA
        self.ratioB = ratioB
        self.isSettled = isSettled
        self.settlementId = settlementId
        self.settledAt = settledAt
    }

    convenience init(
        id: UUID = UUID(),
        pocketId: UUID,
        entryType: PocketEntryType = .expense,
        categoryId: UUID? = nil,
        amount: Int,
        date: Date,
        memo: String = "",
        paymentSource: PaymentSource,
        ratioA: Int = 0,
        ratioB: Int = 0,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.init(
            id: id,
            pocketId: pocketId,
            entryTypeRaw: entryType.rawValue,
            categoryId: categoryId,
            amount: amount,
            date: date,
            memo: memo,
            paymentSourceRaw: paymentSource.rawValue,
            ratioA: ratioA,
            ratioB: ratioB,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt
        )
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
            entryType: .expense,
            categoryId: categoryId,
            amount: amount,
            date: date,
            memo: memo,
            paymentSource: payerRole == .memberA ? .memberA : .memberB,
            ratioA: ratioA,
            ratioB: ratioB,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt
        )
    }
}
