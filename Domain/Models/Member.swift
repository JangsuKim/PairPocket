import Foundation

public enum MemberRole: String, Codable, Hashable {
    case host
    case partner

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self.fromPersistedRawValue(rawValue)
    }

    public static func fromPersistedRawValue(_ rawValue: String) -> MemberRole {
        switch rawValue {
        case "host":
            return .host
        case "partner":
            return .partner
        default:
            return .host
        }
    }

    public var displayName: String {
        switch self {
        case .host:
            return "自分"
        case .partner:
            return "パートナー"
        }
    }
}

public struct Member: Identifiable, Codable, Hashable {
    public var id: UUID
    public var nickname: String
    public var icon: String
    public var role: MemberRole

    public init(
        id: UUID = UUID(),
        nickname: String,
        icon: String = "person.circle.fill",
        role: MemberRole
    ) {
        self.id = id
        self.nickname = nickname
        self.icon = icon
        self.role = role
    }
}
