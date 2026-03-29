import Foundation

public enum PocketMode: String, Codable, Hashable {
    case settlementOnly
    case sharedManagement

    public static func fromPersistedRawValue(_ rawValue: String) -> PocketMode {
        PocketMode(rawValue: rawValue) ?? .settlementOnly
    }

    public var displayName: String {
        switch self {
        case .settlementOnly:
            return "後精算"
        case .sharedManagement:
            return "共有管理"
        }
    }
}

public struct Pocket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorKey: String
    public var icon: String?
    public var ratioHost: Int
    public var ratioPartner: Int
    public var mode: PocketMode
    public var isMain: Bool
    public var createdAt: Date

    public var sharedBalanceEnabled: Bool {
        Self.paymentCapabilities(for: mode).sharedBalanceEnabled
    }

    public var personalPaymentEnabled: Bool {
        Self.paymentCapabilities(for: mode).personalPaymentEnabled
    }

    public static func paymentCapabilities(for mode: PocketMode) -> (
        sharedBalanceEnabled: Bool,
        personalPaymentEnabled: Bool
    ) {
        switch mode {
        case .settlementOnly:
            return (sharedBalanceEnabled: false, personalPaymentEnabled: true)
        case .sharedManagement:
            return (sharedBalanceEnabled: true, personalPaymentEnabled: true)
        }
    }

    // Constraint (not enforced yet): ratioHost + ratioPartner == 100
    public init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioHost: Int = 50,
        ratioPartner: Int = 50,
        mode: PocketMode = .settlementOnly,
        isMain: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.icon = icon
        self.ratioHost = ratioHost
        self.ratioPartner = ratioPartner
        self.mode = mode
        self.isMain = isMain
        self.createdAt = createdAt
    }

}
