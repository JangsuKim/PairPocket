import Foundation

public enum PaymentSource: String, Codable, Hashable {
    case host
    case partner
    case pocket

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self.fromPersistedRawValue(rawValue)
    }

    public static func fromPersistedRawValue(_ rawValue: String) -> PaymentSource {
        switch rawValue {
        case "host":
            return .host
        case "partner":
            return .partner
        case "pocket":
            return .pocket
        default:
            return .host
        }
    }

    public var memberRole: MemberRole? {
        switch self {
        case .host:
            return .host
        case .partner:
            return .partner
        case .pocket:
            return nil
        }
    }

    public var displayName: String {
        switch self {
        case .host, .partner:
            return memberRole?.displayName ?? MemberRole.host.displayName
        case .pocket:
            return "ポケット"
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
    public var createdByUserId: String?
    public var paidByUserId: String?

    public var hostRatio: Int {
        get { ratioA }
        set { ratioA = newValue }
    }

    public var partnerRatio: Int {
        get { ratioB }
        set { ratioB = newValue }
    }

    public var paidBy: MemberRole {
        paymentSource.memberRole ?? .host
    }

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
        settledAt: Date? = nil,
        createdByUserId: String? = nil,
        paidByUserId: String? = nil
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
        self.createdByUserId = createdByUserId
        self.paidByUserId = paidByUserId
    }
}

public typealias Expense = PocketEntry
