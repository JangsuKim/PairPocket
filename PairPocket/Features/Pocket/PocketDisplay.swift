import SwiftUI

extension Pocket {
    var displayColor: Color {
        switch colorKey {
        case "green":
            return .green
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "blue":
            return .blue
        case "pink":
            return .pink
        case "red":
            return .red
        default:
            return .gray
        }
    }
}

enum PocketColorOption: String, CaseIterable, Identifiable {
    case green
    case orange
    case purple
    case blue
    case pink
    case red

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .green:
            return .green
        case .orange:
            return .orange
        case .purple:
            return .purple
        case .blue:
            return .blue
        case .pink:
            return .pink
        case .red:
            return .red
        }
    }
}
