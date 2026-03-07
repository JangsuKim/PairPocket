import Foundation
import Observation

@Observable
final class PocketStore {
    var pockets: [Pocket]

    init(pockets: [Pocket] = PocketStore.defaultPockets) {
        self.pockets = PocketStore.normalizedPockets(from: pockets)
    }

    var mainPocket: Pocket? {
        pockets.first(where: \.isMain)
    }

    var otherPockets: [Pocket] {
        pockets.filter { $0.isMain == false }
    }

    func addPocket(_ pocket: Pocket) {
        pockets.append(pocket)
        normalizeMainPocket(preferredMainID: pocket.isMain ? pocket.id : nil)
    }

    func updatePocket(_ pocket: Pocket) {
        guard let index = pockets.firstIndex(where: { $0.id == pocket.id }) else {
            return
        }

        pockets[index] = pocket
        normalizeMainPocket(preferredMainID: pocket.isMain ? pocket.id : nil)
    }

    func setMainPocket(id: UUID) {
        normalizeMainPocket(preferredMainID: id)
    }

    func pocket(for id: UUID) -> Pocket? {
        pockets.first(where: { $0.id == id })
    }

    private func normalizeMainPocket(preferredMainID: UUID?) {
        guard pockets.isEmpty == false else {
            return
        }

        let fallbackID = preferredMainID
            ?? pockets.first(where: \.isMain)?.id
            ?? pockets[0].id

        pockets = pockets.map { pocket in
            var updatedPocket = pocket
            updatedPocket.isMain = pocket.id == fallbackID
            return updatedPocket
        }
    }

    private static func normalizedPockets(from pockets: [Pocket]) -> [Pocket] {
        guard pockets.isEmpty == false else {
            return []
        }

        let mainID = pockets.first(where: \.isMain)?.id ?? pockets[0].id
        return pockets.map { pocket in
            var updatedPocket = pocket
            updatedPocket.isMain = pocket.id == mainID
            return updatedPocket
        }
    }
}

private extension PocketStore {
    static let defaultPockets: [Pocket] = [
        Pocket(
            id: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "生活費",
            colorKey: "green",
            ratioA: 55,
            ratioB: 45,
            sharedBalanceEnabled: false,
            personalPaymentEnabled: true,
            isMain: true
        ),
        Pocket(
            id: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "旅行",
            colorKey: "orange",
            ratioA: 50,
            ratioB: 50,
            sharedBalanceEnabled: true,
            personalPaymentEnabled: true
        ),
        Pocket(
            id: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "住居",
            colorKey: "purple",
            ratioA: 50,
            ratioB: 50,
            sharedBalanceEnabled: true,
            personalPaymentEnabled: false
        )
    ]
}
