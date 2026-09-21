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

    var artwork: PocketArtwork {
        PocketArtwork(rawValue: icon ?? "") ?? .home
    }
}

enum PocketArtwork: String, CaseIterable, Identifiable {
    case home = "pocket_home"
    case shopping = "pocket_shopping"
    case savings = "pocket_savings"
    case date = "pocket_date"
    case travel = "pocket_travel"
    case camera = "pocket_camera"

    var id: String { rawValue }

    var assetName: String { rawValue }

    var title: String {
        switch self {
        case .home: "家計"
        case .shopping: "買い物"
        case .savings: "貯蓄"
        case .date: "予定"
        case .travel: "旅行"
        case .camera: "趣味"
        }
    }
}

enum PocketSurfaceStyle {
    static func background(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.28),
                color.opacity(0.13)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func border(for color: Color) -> Color {
        color.opacity(0.22)
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
