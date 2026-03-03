import Foundation

struct Pocket: Identifiable {
    let id: Int
    let name: String
    let amountYen: Int
    let count: Int
}

struct PocketSummary {
    let amountYen: Int
    let count: Int
}
