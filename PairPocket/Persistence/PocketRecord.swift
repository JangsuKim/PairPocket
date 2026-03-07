import Foundation
import SwiftData

@Model
final class PocketRecord {
    var id: UUID
    var name: String
    var colorKey: String
    var icon: String?
    var ratioA: Int
    var ratioB: Int
    var sharedBalanceEnabled: Bool
    var personalPaymentEnabled: Bool
    var isMain: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioA: Int,
        ratioB: Int,
        sharedBalanceEnabled: Bool,
        personalPaymentEnabled: Bool,
        isMain: Bool,
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
        self.isMain = isMain
        self.createdAt = createdAt
    }
}

extension PocketRecord {
    convenience init(pocket: Pocket) {
        self.init(
            id: pocket.id,
            name: pocket.name,
            colorKey: pocket.colorKey,
            icon: pocket.icon,
            ratioA: pocket.ratioA,
            ratioB: pocket.ratioB,
            sharedBalanceEnabled: pocket.sharedBalanceEnabled,
            personalPaymentEnabled: pocket.personalPaymentEnabled,
            isMain: pocket.isMain,
            createdAt: pocket.createdAt
        )
    }

    var pocket: Pocket {
        Pocket(
            id: id,
            name: name,
            colorKey: colorKey,
            icon: icon,
            ratioA: ratioA,
            ratioB: ratioB,
            sharedBalanceEnabled: sharedBalanceEnabled,
            personalPaymentEnabled: personalPaymentEnabled,
            isMain: isMain,
            createdAt: createdAt
        )
    }
}
