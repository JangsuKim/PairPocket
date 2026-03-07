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
            guard let entryType = PocketEntryType(rawValue: entryTypeRaw) else {
                preconditionFailure("Unsupported entryTypeRaw: \(entryTypeRaw)")
            }

            return entryType
        }
        set {
            entryTypeRaw = newValue.rawValue
        }
    }

    var paymentSource: PaymentSource {
        get {
            guard let paymentSource = PaymentSource(rawValue: paymentSourceRaw) else {
                preconditionFailure("Unsupported paymentSourceRaw: \(paymentSourceRaw)")
            }

            return paymentSource
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
            ratioA: entry.ratioA,
            ratioB: entry.ratioB,
            isSettled: entry.isSettled,
            settlementId: entry.settlementId,
            settledAt: entry.settledAt
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
            ratioA: ratioA,
            ratioB: ratioB,
            memo: memo.isEmpty ? nil : memo,
            date: date,
            createdAt: date,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt
        )
    }
}
