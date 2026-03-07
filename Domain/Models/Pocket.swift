import Foundation

public struct Pocket: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorKey: String
    public var icon: String?
    public var ratioA: Int
    public var ratioB: Int
    public var sharedBalanceEnabled: Bool
    public var personalPaymentEnabled: Bool
    public var createdAt: Date

    // Constraint (not enforced yet): ratioA + ratioB == 100
    public init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioA: Int = 50,
        ratioB: Int = 50,
        sharedBalanceEnabled: Bool = false,
        personalPaymentEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.icon = icon
        self.ratioA = ratioA
        self.ratioB = ratioB
        self.sharedBalanceEnabled = sharedBalanceEnabled
        self.personalPaymentEnabled = personalPaymentEnabled
        self.createdAt = createdAt
    }
}
