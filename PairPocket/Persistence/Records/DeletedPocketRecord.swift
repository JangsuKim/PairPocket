import Foundation
import SwiftData

@Model
final class DeletedPocketRecord {
    var pocketId: UUID
    var deletedAt: Date

    init(pocketId: UUID, deletedAt: Date = Date()) {
        self.pocketId = pocketId
        self.deletedAt = deletedAt
    }
}
