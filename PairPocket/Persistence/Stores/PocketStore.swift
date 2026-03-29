import Foundation
import Observation
import SwiftData

@Observable
final class PocketStore {
    static let maximumPocketCount = 5

    private(set) var allPockets: [Pocket] = []
    private(set) var pockets: [Pocket] = []
    private var hasLoaded = false

    var mainPocket: Pocket? {
        pockets.first(where: \.isMain)
    }

    func loadIfNeeded(from modelContext: ModelContext) throws {
        guard hasLoaded == false else {
            return
        }

        try reload(from: modelContext)
        hasLoaded = true
    }

    func reload(from modelContext: ModelContext) throws {
        let records = try fetchPocketRecords(from: modelContext)

        if records.isEmpty {
            for pocket in Self.defaultPockets {
                modelContext.insert(PocketRecord(pocket: pocket))
            }
            try modelContext.save()
        }

        let refreshedRecords = try fetchPocketRecords(from: modelContext)
        let deletedIDs = try fetchDeletedPocketIDs(from: modelContext)
        syncState(from: refreshedRecords.map(\.pocket), deletedPocketIDs: deletedIDs)
    }

    func addPocket(_ pocket: Pocket, in modelContext: ModelContext) throws {
        guard pockets.count < Self.maximumPocketCount else {
            throw PocketStoreError.pocketLimitExceeded(maximum: Self.maximumPocketCount)
        }

        modelContext.insert(PocketRecord(pocket: pocket))
        try persistMainPocket(preferredMainID: pocket.isMain ? pocket.id : nil, in: modelContext)
    }

    func addPocket(
        _ pocket: Pocket,
        defaultCategoryName: String,
        in modelContext: ModelContext
    ) throws {
        guard pockets.count < Self.maximumPocketCount else {
            throw PocketStoreError.pocketLimitExceeded(maximum: Self.maximumPocketCount)
        }

        let trimmedCategoryName = defaultCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)

        modelContext.insert(PocketRecord(pocket: pocket))

        if trimmedCategoryName.isEmpty == false {
            let category = Category(
                pocketId: pocket.id,
                name: trimmedCategoryName,
                sortOrder: 0,
                isDefault: true
            )
            modelContext.insert(CategoryRecord(category: category))
        }

        try persistMainPocket(preferredMainID: pocket.isMain ? pocket.id : nil, in: modelContext)
    }

    func updatePocket(_ pocket: Pocket, in modelContext: ModelContext) throws {
        let record = try fetchPocketRecord(id: pocket.id, from: modelContext)
        record.name = pocket.name
        record.colorKey = pocket.colorKey
        record.icon = pocket.icon
        record.ratioHost = pocket.ratioHost
        record.ratioPartner = pocket.ratioPartner
        record.mode = pocket.mode
        record.isMain = pocket.isMain
        record.createdAt = pocket.createdAt

        try persistMainPocket(preferredMainID: pocket.isMain ? pocket.id : nil, in: modelContext)
    }

    func softDeletePocket(id: UUID, in modelContext: ModelContext) throws {
        let record = try fetchPocketRecord(id: id, from: modelContext)

        guard record.isMain == false else {
            throw PocketStoreError.mainPocketDeletionNotAllowed
        }

        if try deletedPocketRecord(id: id, from: modelContext) == nil {
            modelContext.insert(DeletedPocketRecord(pocketId: id))
        }

        try persistMainPocket(preferredMainID: nil, in: modelContext)
    }

    func setMainPocket(id: UUID, in modelContext: ModelContext) throws {
        try persistMainPocket(preferredMainID: id, in: modelContext)
    }

    func pocket(for id: UUID, includeDeleted: Bool = false) -> Pocket? {
        let source = includeDeleted ? allPockets : pockets
        return source.first(where: { $0.id == id })
    }

    private func persistMainPocket(preferredMainID: UUID?, in modelContext: ModelContext) throws {
        let records = try fetchPocketRecords(from: modelContext)
        let deletedIDs = try fetchDeletedPocketIDs(from: modelContext)
        let activeIDs = records.map(\.id).filter { deletedIDs.contains($0) == false }

        if activeIDs.isEmpty {
            for record in records {
                record.isMain = false
            }
            try modelContext.save()
            syncState(from: records.map(\.pocket), deletedPocketIDs: deletedIDs)
            return
        }

        let currentMainID = records.first(where: { deletedIDs.contains($0.id) == false && $0.isMain })?.id
        let fallbackID = preferredMainID ?? currentMainID ?? activeIDs[0]

        for record in records {
            record.isMain = deletedIDs.contains(record.id) == false && record.id == fallbackID
        }

        try modelContext.save()
        syncState(from: records.map(\.pocket), deletedPocketIDs: deletedIDs)
    }

    private func fetchPocketRecords(from modelContext: ModelContext) throws -> [PocketRecord] {
        let descriptor = FetchDescriptor<PocketRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchPocketRecord(id: UUID, from modelContext: ModelContext) throws -> PocketRecord {
        let predicate = #Predicate<PocketRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<PocketRecord>(predicate: predicate)

        guard let record = try modelContext.fetch(descriptor).first else {
            throw PocketStoreError.pocketNotFound
        }

        return record
    }

    private func fetchDeletedPocketIDs(from modelContext: ModelContext) throws -> Set<UUID> {
        let descriptor = FetchDescriptor<DeletedPocketRecord>()
        let deletedRecords = try modelContext.fetch(descriptor)
        return Set(deletedRecords.map(\.pocketId))
    }

    private func deletedPocketRecord(id: UUID, from modelContext: ModelContext) throws -> DeletedPocketRecord? {
        let predicate = #Predicate<DeletedPocketRecord> { record in
            record.pocketId == id
        }
        let descriptor = FetchDescriptor<DeletedPocketRecord>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    private func syncState(from pockets: [Pocket], deletedPocketIDs: Set<UUID>) {
        allPockets = pockets
        self.pockets = pockets.filter { deletedPocketIDs.contains($0.id) == false }
    }
}

enum PocketStoreError: LocalizedError {
    case pocketNotFound
    case mainPocketDeletionNotAllowed
    case pocketLimitExceeded(maximum: Int)

    var errorDescription: String? {
        switch self {
        case .pocketNotFound:
            return "ポケットが見つかりません。"
        case .mainPocketDeletionNotAllowed:
            return "メインポケットは削除できません。"
        case let .pocketLimitExceeded(maximum):
            return "ポケットは最大\(maximum)個まで作成できます。"
        }
    }
}

private extension PocketStore {
    static let defaultPockets: [Pocket] = [
        Pocket(
            id: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "生活費",
            colorKey: "mint",
            ratioHost: 50,
            ratioPartner: 50,
            mode: .settlementOnly,
            isMain: true
        )
    ]
}
