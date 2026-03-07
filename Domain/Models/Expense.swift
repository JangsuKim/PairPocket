import Foundation

public enum PaymentSource: String, Codable, Hashable {
    case memberA
    case memberB
    case pocket

    public var memberRole: MemberRole? {
        switch self {
        case .memberA:
            return .memberA
        case .memberB:
            return .memberB
        case .pocket:
            return nil
        }
    }
}

public enum PocketEntryType: String, Codable, Hashable {
    case expense
    case deposit
}

public struct PocketEntry: Identifiable, Codable, Hashable {
    public var id: UUID
    public var pocketId: UUID
    public var type: PocketEntryType
    public var categoryId: UUID?
    public var paymentSource: PaymentSource
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
}

public typealias Expense = PocketEntry
