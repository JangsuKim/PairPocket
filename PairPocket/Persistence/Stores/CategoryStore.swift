import Foundation
import Observation
import SwiftData

@Observable
final class CategoryStore {
    enum CategoryStoreError: LocalizedError {
        case cannotDeactivateLastActiveCategory

        var errorDescription: String? {
            switch self {
            case .cannotDeactivateLastActiveCategory:
                return "カテゴリは1つ以上必要です。"
            }
        }
    }

    private(set) var categories: [Category] = []
    private var hasLoaded = false

    func loadIfNeeded(from modelContext: ModelContext) throws {
        guard hasLoaded == false else {
            return
        }

        try reload(from: modelContext)
        hasLoaded = true
    }

    func reload(from modelContext: ModelContext) throws {
        let records = try fetchCategoryRecords(from: modelContext)

        if records.isEmpty {
            for category in Self.defaultCategories {
                modelContext.insert(CategoryRecord(category: category))
            }

            try modelContext.save()
        }

        let refreshedRecords = try fetchCategoryRecords(from: modelContext)
        categories = refreshedRecords.map(\.category)
    }

    func categories(for pocketId: UUID) -> [Category] {
        categories
            .filter { $0.pocketId == pocketId }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    @discardableResult
    func addCategory(name: String, to pocketId: UUID, in modelContext: ModelContext) throws -> Category? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else { return nil }

        let nextSortOrder = (categories(for: pocketId).map(\.sortOrder).max() ?? -1) + 1
        let category = Category(
            pocketId: pocketId,
            name: trimmedName,
            sortOrder: nextSortOrder
        )

        modelContext.insert(CategoryRecord(category: category))
        try modelContext.save()
        try reload(from: modelContext)
        return category
    }

    func renameCategory(id: UUID, to name: String, in modelContext: ModelContext) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else { return }
        guard let record = try fetchCategoryRecord(id: id, from: modelContext) else { return }

        record.name = trimmedName
        try modelContext.save()
        try reload(from: modelContext)
    }

    func setCategoryActive(id: UUID, isActive: Bool, in modelContext: ModelContext) throws {
        guard let record = try fetchCategoryRecord(id: id, from: modelContext) else { return }
        guard record.isActive != isActive else { return }

        if isActive == false {
            let activeCount = categories(for: record.pocketId).filter(\.isActive).count
            guard activeCount > 1 else {
                throw CategoryStoreError.cannotDeactivateLastActiveCategory
            }
        }

        record.isActive = isActive
        try modelContext.save()
        try reload(from: modelContext)
    }

    func moveCategories(
        in pocketId: UUID,
        fromOffsets: IndexSet,
        toOffset: Int,
        in modelContext: ModelContext
    ) throws {
        guard fromOffsets.isEmpty == false else { return }

        let pocketRecords = try fetchCategoryRecords(for: pocketId, from: modelContext)
        guard pocketRecords.isEmpty == false else { return }

        var reorderedRecords = pocketRecords
        let movingRecords = fromOffsets.sorted().map { reorderedRecords[$0] }

        for sourceIndex in fromOffsets.sorted(by: >) {
            reorderedRecords.remove(at: sourceIndex)
        }

        let destinationIndex = min(max(toOffset, 0), reorderedRecords.count)
        reorderedRecords.insert(contentsOf: movingRecords, at: destinationIndex)

        for (index, reorderedRecord) in reorderedRecords.enumerated() {
            reorderedRecord.sortOrder = index
        }

        try modelContext.save()
        try reload(from: modelContext)
    }

    func deleteCategory(id: UUID, in modelContext: ModelContext) throws {
        guard let record = try fetchCategoryRecord(id: id, from: modelContext) else { return }

        modelContext.delete(record)
        try modelContext.save()
        try reload(from: modelContext)
    }
}

private extension CategoryStore {
    func fetchCategoryRecords(from modelContext: ModelContext) throws -> [CategoryRecord] {
        let descriptor = FetchDescriptor<CategoryRecord>(
            sortBy: [
                SortDescriptor(\.pocketId, order: .forward),
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.name, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCategoryRecord(id: UUID, from modelContext: ModelContext) throws -> CategoryRecord? {
        let predicate = #Predicate<CategoryRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<CategoryRecord>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }

    func fetchCategoryRecords(for pocketId: UUID, from modelContext: ModelContext) throws -> [CategoryRecord] {
        let predicate = #Predicate<CategoryRecord> { record in
            record.pocketId == pocketId
        }
        let descriptor = FetchDescriptor<CategoryRecord>(
            predicate: predicate,
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.name, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor)
    }
}

private extension CategoryStore {
    static let defaultCategories: [Category] = [
        Category(
            id: UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "スーパー",
            sortOrder: 0,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "E8F9E3FD-6309-4FA4-B36B-D5CF5B0E56A7")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "ドラッグストア",
            sortOrder: 1,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "5C2EAE9B-349B-40BA-9817-9A0E13CE35F3")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "オンライン通販",
            sortOrder: 2,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "BFE80144-9D6A-47B0-B4D9-83096E74CF23")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "コンビニ",
            sortOrder: 3,
            isDefault: true
        ),
    ]
}
