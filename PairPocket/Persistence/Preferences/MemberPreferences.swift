import Foundation

enum MemberIconSource {
    case asset(String)
    case system(String)
}

enum MemberPreferenceKeys {
    static let hostName = "settings.host.name"
    static let hostIcon = "settings.host.icon"
    static let hostPhotoData = "settings.host.photoData"
    static let hostUploadedPhotoData = "settings.host.uploadedPhotoData"
    static let hostUploadedPhotoHistory = "settings.host.uploadedPhotoHistory"
    static let partnerName = "settings.partner.name"
    static let partnerIcon = "settings.partner.icon"
    static let partnerPhotoData = "settings.partner.photoData"
    static let partnerUploadedPhotoData = "settings.partner.uploadedPhotoData"
    static let partnerUploadedPhotoHistory = "settings.partner.uploadedPhotoHistory"

    static let currentMemberRole = "currentMemberRole"
    static let localUserId = "localUserId"
    static let relationshipIsLinked = "relationship.isLinked"
    static let relationshipCoupleId = "relationship.coupleId"
    static let relationshipHostUserId = "relationship.hostUserId"
    static let relationshipPartnerUserId = "relationship.partnerUserId"
}

enum MemberPreferences {
    static let defaultMemberIconAssetName = "DefaultMemberIconGray"
    static let selectableDefaultIconAssetNames = [
        "DefaultMemberIconBlue",
        "DefaultMemberIconPink"
    ]
    static let uploadedPhotoHistoryLimit = 8

    static var allSupportedIconAssetNames: Set<String> {
        Set([defaultMemberIconAssetName] + selectableDefaultIconAssetNames)
    }

    static func resolvedIconSource(storedIconName: String, for role: MemberRole) -> MemberIconSource {
        let trimmed = storedIconName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == legacySystemIconName(for: role) {
            return .asset(defaultMemberIconAssetName)
        }
        if allSupportedIconAssetNames.contains(trimmed) {
            return .asset(trimmed)
        }
        return .system(trimmed)
    }

    static func migrateLegacyValues(defaults: UserDefaults = .standard) {
        let role = defaults.string(forKey: MemberPreferenceKeys.currentMemberRole)
        guard role == nil || role == MemberRole.host.rawValue || role == MemberRole.partner.rawValue else {
            defaults.set(MemberRole.host.rawValue, forKey: MemberPreferenceKeys.currentMemberRole)
            return
        }

        migrateLegacyUploadedPhotoIfNeeded(for: .host, defaults: defaults)
        migrateLegacyUploadedPhotoIfNeeded(for: .partner, defaults: defaults)
    }

    static func uploadedPhotoHistory(for role: MemberRole, defaults: UserDefaults = .standard) -> [Data] {
        guard let data = defaults.data(forKey: uploadedPhotoHistoryKey(for: role)),
              let decoded = try? JSONDecoder().decode([Data].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveUploadedPhotoHistory(_ photos: [Data], for role: MemberRole, defaults: UserDefaults = .standard) {
        let sanitized = photos.filter { $0.isEmpty == false }
        guard let encoded = try? JSONEncoder().encode(sanitized) else {
            return
        }
        defaults.set(encoded, forKey: uploadedPhotoHistoryKey(for: role))
    }

    static func appendUploadedPhoto(_ photoData: Data, for role: MemberRole, defaults: UserDefaults = .standard) {
        guard photoData.isEmpty == false else {
            return
        }

        var history = uploadedPhotoHistory(for: role, defaults: defaults)
        history.removeAll(where: { $0 == photoData })
        history.insert(photoData, at: 0)
        if history.count > uploadedPhotoHistoryLimit {
            history = Array(history.prefix(uploadedPhotoHistoryLimit))
        }
        saveUploadedPhotoHistory(history, for: role, defaults: defaults)
    }

    static func removeUploadedPhoto(at index: Int, for role: MemberRole, defaults: UserDefaults = .standard) {
        var history = uploadedPhotoHistory(for: role, defaults: defaults)
        guard history.indices.contains(index) else {
            return
        }
        history.remove(at: index)
        saveUploadedPhotoHistory(history, for: role, defaults: defaults)
    }

    static func fallbackName(for role: MemberRole) -> String {
        role.displayName
    }

    static func memberDisplayName(for role: MemberRole, defaults: UserDefaults = .standard) -> String {
        let key: String
        switch role {
        case .host:
            key = MemberPreferenceKeys.hostName
        case .partner:
            key = MemberPreferenceKeys.partnerName
        }

        let storedName = defaults.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return storedName.isEmpty ? fallbackName(for: role) : storedName
    }

    static func payerMemberName(
        paymentSource: PaymentSource,
        paidByUserId: String?,
        localUserId: String,
        defaults: UserDefaults = .standard
    ) -> String {
        if let role = paymentSource.memberRole {
            return memberDisplayName(for: role, defaults: defaults)
        }

        let currentRole = MemberRole.fromPersistedRawValue(
            defaults.string(forKey: MemberPreferenceKeys.currentMemberRole) ?? MemberRole.host.rawValue
        )

        guard let paidByUserId, paidByUserId.isEmpty == false else {
            return paymentSource.displayName
        }

        let payerRole: MemberRole = paidByUserId == localUserId
            ? currentRole
            : (currentRole == .host ? .partner : .host)
        return memberDisplayName(for: payerRole, defaults: defaults)
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

    private static func legacySystemIconName(for role: MemberRole) -> String {
        switch role {
        case .host:
            return "person.circle.fill"
        case .partner:
            return "person.circle"
        }
    }

    private static func uploadedPhotoHistoryKey(for role: MemberRole) -> String {
        switch role {
        case .host:
            return MemberPreferenceKeys.hostUploadedPhotoHistory
        case .partner:
            return MemberPreferenceKeys.partnerUploadedPhotoHistory
        }
    }

    private static func legacyUploadedPhotoKey(for role: MemberRole) -> String {
        switch role {
        case .host:
            return MemberPreferenceKeys.hostUploadedPhotoData
        case .partner:
            return MemberPreferenceKeys.partnerUploadedPhotoData
        }
    }

    private static func migrateLegacyUploadedPhotoIfNeeded(for role: MemberRole, defaults: UserDefaults) {
        if uploadedPhotoHistory(for: role, defaults: defaults).isEmpty == false {
            return
        }

        guard let legacyData = defaults.data(forKey: legacyUploadedPhotoKey(for: role)),
              legacyData.isEmpty == false else {
            return
        }

        saveUploadedPhotoHistory([legacyData], for: role, defaults: defaults)
    }
}
