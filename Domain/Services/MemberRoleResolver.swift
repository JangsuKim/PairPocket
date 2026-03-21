import Foundation

public enum MemberRoleResolver {
    public static func role(of userId: String, in context: RelationshipContext) -> MemberRole? {
        guard context.isLinked else {
            return nil
        }

        if context.hostUserId == userId {
            return .host
        }

        if context.partnerUserId == userId {
            return .partner
        }

        return nil
    }

    public static func userId(for role: MemberRole, in context: RelationshipContext) -> String? {
        guard context.isLinked else {
            return nil
        }

        switch role {
        case .host:
            return context.hostUserId
        case .partner:
            return context.partnerUserId
        }
    }
}
