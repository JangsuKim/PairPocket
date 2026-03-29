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
    var ratioHost: Int
    var ratioPartner: Int
    var isSettled: Bool
    var settlementId: UUID?
    var settledAt: Date?
    var createdByUserId: String?
    var paidByUserId: String?

    var entryType: PocketEntryType {
        get {
            PocketEntryType.fromPersistedRawValue(entryTypeRaw)
        }
        set {
            entryTypeRaw = newValue.rawValue
        }
    }

    var paymentSource: PaymentSource {
        get {
            PaymentSource.fromPersistedRawValue(paymentSourceRaw)
        }
        set {
            paymentSourceRaw = newValue.rawValue
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
        paymentSourceRaw: String = PaymentSource.host.rawValue,
        ratioHost: Int,
        ratioPartner: Int,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil,
        createdByUserId: String? = nil,
        paidByUserId: String? = nil
    ) {
        self.id = id
        self.pocketId = pocketId
        self.entryTypeRaw = entryTypeRaw
        self.categoryId = categoryId
        self.amount = amount
        self.date = date
        self.memo = memo
        self.paymentSourceRaw = PaymentSource.fromPersistedRawValue(paymentSourceRaw).rawValue
        self.ratioHost = ratioHost
        self.ratioPartner = ratioPartner
        self.isSettled = isSettled
        self.settlementId = settlementId
        self.settledAt = settledAt
        self.createdByUserId = createdByUserId
        self.paidByUserId = paidByUserId
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
        ratioHost: Int = 0,
        ratioPartner: Int = 0,
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil,
        createdByUserId: String? = nil,
        paidByUserId: String? = nil
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
            ratioHost: ratioHost,
            ratioPartner: ratioPartner,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt,
            createdByUserId: createdByUserId,
            paidByUserId: paidByUserId
        )
    }

}

extension ExpenseRecord {
    convenience init(entry: PocketEntry) {
        self.init(
            id: entry.id,
            pocketId: entry.pocketId,
            entryType: entry.type,
            categoryId: entry.categoryId,
            amount: entry.amount,
            date: entry.date,
            memo: entry.memo ?? "",
            paymentSource: entry.paymentSource,
            ratioHost: entry.ratioHost,
            ratioPartner: entry.ratioPartner,
            isSettled: entry.isSettled,
            settlementId: entry.settlementId,
            settledAt: entry.settledAt,
            createdByUserId: entry.createdByUserId,
            paidByUserId: entry.paidByUserId
        )
    }

    var pocketEntry: PocketEntry {
        PocketEntry(
            id: id,
            pocketId: pocketId,
            type: entryType,
            categoryId: categoryId,
            paymentSource: paymentSource,
            amount: amount,
            ratioHost: ratioHost,
            ratioPartner: ratioPartner,
            memo: memo.isEmpty ? nil : memo,
            date: date,
            createdAt: date,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt,
            createdByUserId: createdByUserId,
            paidByUserId: paidByUserId
        )
    }
}
