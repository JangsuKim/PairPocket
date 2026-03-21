import Foundation

public struct RelationshipContext: Codable, Hashable {
    public var isLinked: Bool
    public var coupleId: String?
    public var hostUserId: String?
    public var partnerUserId: String?

    public init(
        isLinked: Bool = false,
        coupleId: String? = nil,
        hostUserId: String? = nil,
        partnerUserId: String? = nil
    ) {
        self.isLinked = isLinked
        self.coupleId = coupleId
        self.hostUserId = hostUserId
        self.partnerUserId = partnerUserId
    }

    public static var standalone: RelationshipContext {
        RelationshipContext(isLinked: false)
    }

    public var hasValidLinkedIdentity: Bool {
        isLinked && hostUserId?.isEmpty == false && partnerUserId?.isEmpty == false
    }
}
