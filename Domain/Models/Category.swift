import Foundation

public struct Category: Identifiable, Codable, Hashable {
    public var id: UUID
    public var pocketId: UUID
    public var name: String
    public var icon: String?
    public var sortOrder: Int
    public var isDefault: Bool

    public init(
        id: UUID = UUID(),
        pocketId: UUID,
        name: String,
        icon: String? = nil,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.pocketId = pocketId
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}
