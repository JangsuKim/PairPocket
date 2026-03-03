import SwiftUI

struct Pocket: Identifiable {
    let id: Int
    let name: String
    let amountYen: Int
    let count: Int
    let color: Color

    init(id: Int, name: String, amountYen: Int, count: Int, color: Color = .blue) {
        self.id = id
        self.name = name
        self.amountYen = amountYen
        self.count = count
        self.color = color
    }
}

struct PocketSummary {
    let amountYen: Int
    let count: Int
}
