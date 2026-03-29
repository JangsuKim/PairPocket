import SwiftUI

extension Pocket {
    var displayColor: Color {
        switch colorKey {
        case "mint":
            return Color("PocketMint")
        case "peach":
            return Color("PocketPeach")
        case "lavender":
            return Color("PocketLavender")
        case "sky":
            return Color("PocketSky")
        case "blush":
            return Color("PocketBlush")
        default:
            return Color("PocketMint")
        }
    }
}

enum PocketColorOption: String, CaseIterable, Identifiable {
    case mint
    case peach
    case lavender
    case sky
    case blush

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .mint:
            return Color("PocketMint")
        case .peach:
            return Color("PocketPeach")
        case .lavender:
            return Color("PocketLavender")
        case .sky:
            return Color("PocketSky")
        case .blush:
            return Color("PocketBlush")
        }
    }
}
