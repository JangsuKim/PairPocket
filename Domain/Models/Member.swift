import Foundation

public enum MemberRole: String, Codable, Hashable {
    case a
    case b
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
