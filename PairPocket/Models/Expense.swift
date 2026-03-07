import Foundation

enum MemberRole: String, Codable, Hashable {
    case memberA
    case memberB
}

enum PaymentSource: String, Codable, Hashable {
    case memberA
    case memberB
    case pocket

    var payerRole: MemberRole? {
        switch self {
        case .memberA:
            return .memberA
        case .memberB:
            return .memberB
        case .pocket:
            return nil
        }
    }

    init(storageValue: String) {
        switch storageValue {
        case "memberA":
            self = .memberA
        case "memberB":
            self = .memberB
        case "pocket":
            self = .pocket
        default:
            self = .memberA
        }
    }
}

enum PocketEntryType: String, Codable, Hashable {
    case expense
    case deposit
}

struct Expense: Identifiable, Codable, Hashable {
    var id: UUID
    var pocketId: UUID
    var type: PocketEntryType
    var categoryId: UUID?
    var paymentSource: PaymentSource
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
        type: PocketEntryType = .expense,
        categoryId: UUID? = nil,
        paymentSource: PaymentSource,
        amount: Int,
        ratioA: Int = 0,
        ratioB: Int = 0,
        memo: String? = nil,
        date: Date,
        createdAt: Date = Date(),
        isSettled: Bool = false,
        settlementId: UUID? = nil,
        settledAt: Date? = nil
    ) {
        self.id = id
        self.pocketId = pocketId
        self.type = type
        self.categoryId = categoryId
        self.paymentSource = paymentSource
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

    init(
        id: UUID = UUID(),
        pocketId: UUID,
        categoryId: UUID,
        payerRole: MemberRole = .memberA,
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
        self.init(
            id: id,
            pocketId: pocketId,
            type: .expense,
            categoryId: categoryId,
            paymentSource: payerRole == .memberA ? .memberA : .memberB,
            amount: amount,
            ratioA: ratioA,
            ratioB: ratioB,
            memo: memo,
            date: date,
            createdAt: createdAt,
            isSettled: isSettled,
            settlementId: settlementId,
            settledAt: settledAt
        )
    }

    var payerRole: MemberRole? {
        paymentSource.payerRole
    }
}
