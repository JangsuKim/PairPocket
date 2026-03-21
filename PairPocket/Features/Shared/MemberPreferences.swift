import Foundation

enum MemberPreferenceKeys {
    static let hostName = "settings.host.name"
    static let hostIcon = "settings.host.icon"
    static let partnerName = "settings.partner.name"
    static let partnerIcon = "settings.partner.icon"

    static let currentMemberRole = "currentMemberRole"
    static let localUserId = "localUserId"
    static let relationshipIsLinked = "relationship.isLinked"
    static let relationshipCoupleId = "relationship.coupleId"
    static let relationshipHostUserId = "relationship.hostUserId"
    static let relationshipPartnerUserId = "relationship.partnerUserId"
}

enum MemberPreferences {
    static func migrateLegacyValues(defaults: UserDefaults = .standard) {
        let role = defaults.string(forKey: MemberPreferenceKeys.currentMemberRole)
        guard role == nil || role == MemberRole.host.rawValue || role == MemberRole.partner.rawValue else {
            defaults.set(MemberRole.host.rawValue, forKey: MemberPreferenceKeys.currentMemberRole)
            return
        }
    }

    static func fallbackName(for role: MemberRole) -> String {
        role.displayName
    }

    static func payerDisplayName(paymentSource: PaymentSource, paidByUserId: String?, localUserId: String) -> String {
        guard let paidByUserId, paidByUserId.isEmpty == false else {
            return paymentSource.displayName
        }

        return paidByUserId == localUserId ? "自分" : "パートナー"
    }

    static func relationshipContext(defaults: UserDefaults = .standard) -> RelationshipContext {
        RelationshipContext(
            isLinked: defaults.bool(forKey: MemberPreferenceKeys.relationshipIsLinked),
            coupleId: defaults.string(forKey: MemberPreferenceKeys.relationshipCoupleId),
            hostUserId: defaults.string(forKey: MemberPreferenceKeys.relationshipHostUserId),
            partnerUserId: defaults.string(forKey: MemberPreferenceKeys.relationshipPartnerUserId)
        )
    }

    static func saveRelationshipContext(_ context: RelationshipContext, defaults: UserDefaults = .standard) {
        defaults.set(context.isLinked, forKey: MemberPreferenceKeys.relationshipIsLinked)
        defaults.set(context.coupleId, forKey: MemberPreferenceKeys.relationshipCoupleId)
        defaults.set(context.hostUserId, forKey: MemberPreferenceKeys.relationshipHostUserId)
        defaults.set(context.partnerUserId, forKey: MemberPreferenceKeys.relationshipPartnerUserId)
    }

    static func resolvePaidByUserId(
        paymentSource: PaymentSource,
        localUserId: String,
        localRole: MemberRole,
        relationship: RelationshipContext
    ) -> String? {
        guard let payerRole = paymentSource.memberRole else {
            return nil
        }

        if relationship.hasValidLinkedIdentity {
            return MemberRoleResolver.userId(for: payerRole, in: relationship)
        }

        return payerRole == localRole ? localUserId : nil
    }

    static func resolvePaidByUserId(
        paymentSource: PaymentSource,
        localUserId: String,
        localRole: MemberRole,
        defaults: UserDefaults = .standard
    ) -> String? {
        resolvePaidByUserId(
            paymentSource: paymentSource,
            localUserId: localUserId,
            localRole: localRole,
            relationship: relationshipContext(defaults: defaults)
        )
    }

    @discardableResult
    static func ensureLocalUserId(defaults: UserDefaults = .standard) -> String {
        if let existing = defaults.string(forKey: MemberPreferenceKeys.localUserId), existing.isEmpty == false {
            return existing
        }

        let generated = UUID().uuidString
        defaults.set(generated, forKey: MemberPreferenceKeys.localUserId)
        return generated
    }

    // Reserved hook for future invite/link migrations.
    static func backfillRelationshipContextIfNeeded(defaults: UserDefaults = .standard) {
        let context = relationshipContext(defaults: defaults)
        if context.isLinked == false {
            return
        }

        if context.hasValidLinkedIdentity == false {
            saveRelationshipContext(.standalone, defaults: defaults)
        }
    }
}
