import Foundation
import SwiftData

@Model
final class PocketRecord {
    var id: UUID
    var name: String
    var colorKey: String
    var icon: String?
    var ratioHost: Int
    var ratioPartner: Int
    var modeRaw: String
    var isMain: Bool
    var createdAt: Date

    var mode: PocketMode {
        get {
            PocketMode.fromPersistedRawValue(modeRaw)
        }
        set {
            modeRaw = newValue.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioHost: Int,
        ratioPartner: Int,
        modeRaw: String,
        isMain: Bool,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.icon = icon
        self.ratioHost = ratioHost
        self.ratioPartner = ratioPartner
        self.modeRaw = PocketMode.fromPersistedRawValue(modeRaw).rawValue
        self.isMain = isMain
        self.createdAt = createdAt
    }

    convenience init(
        id: UUID = UUID(),
        name: String,
        colorKey: String,
        icon: String? = nil,
        ratioHost: Int,
        ratioPartner: Int,
        mode: PocketMode,
        isMain: Bool,
        createdAt: Date = Date()
    ) {
        self.init(
            id: id,
            name: name,
            colorKey: colorKey,
            icon: icon,
            ratioHost: ratioHost,
            ratioPartner: ratioPartner,
            modeRaw: mode.rawValue,
            isMain: isMain,
            createdAt: createdAt
        )
    }
}

extension PocketRecord {
    convenience init(pocket: Pocket) {
        self.init(
            id: pocket.id,
            name: pocket.name,
            colorKey: pocket.colorKey,
            icon: pocket.icon,
            ratioHost: pocket.ratioHost,
            ratioPartner: pocket.ratioPartner,
            mode: pocket.mode,
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
            ratioHost: ratioHost,
            ratioPartner: ratioPartner,
            mode: mode,
            isMain: isMain,
            createdAt: createdAt
        )
    }
}
