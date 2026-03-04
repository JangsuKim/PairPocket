import Foundation

public struct Pocket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorKey: String
    public var icon: String?
    public var ratioMe: Int
    public var ratioPartner: Int
    public var createdAt: Date

    // Constraint (not enforced yet): ratioMe + ratioPartner == 100
    public init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioMe: Int = 50,
        ratioPartner: Int = 50,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.icon = icon
        self.ratioMe = ratioMe
        self.ratioPartner = ratioPartner
        self.createdAt = createdAt
    }
}
