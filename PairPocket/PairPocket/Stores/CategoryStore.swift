import Foundation
import Observation
import SwiftData

@Observable
final class CategoryStore {
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
}

private extension CategoryStore {
    static let defaultCategories: [Category] = [
        Category(
            id: UUID(uuidString: "A1F1EAF5-0F59-4A33-B5B6-3A1F8F8B3B01")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "食費",
            sortOrder: 0,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "E8F9E3FD-6309-4FA4-B36B-D5CF5B0E56A7")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "カフェ",
            sortOrder: 1,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "5C2EAE9B-349B-40BA-9817-9A0E13CE35F3")!,
            pocketId: UUID(uuidString: "8D5ECF10-76C4-4F6A-9F65-ED104FB43311")!,
            name: "生活",
            sortOrder: 2,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "BFE80144-9D6A-47B0-B4D9-83096E74CF23")!,
            pocketId: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "交通",
            sortOrder: 0,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "D2D8E4E9-D2A2-4C6A-840B-CCDBF07D82AD")!,
            pocketId: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "宿泊",
            sortOrder: 1,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "F1BFAFF3-CC02-4624-A6B7-92E0A44C508B")!,
            pocketId: UUID(uuidString: "0B51A05D-934F-4F02-BFE5-6CBA8AFBA761")!,
            name: "食事",
            sortOrder: 2,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "09D8C552-3A9A-43C7-8590-C8BE17DEDBD6")!,
            pocketId: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "家賃",
            sortOrder: 0,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "5B0A7D25-AB55-4C57-87E9-2BBEC54B028E")!,
            pocketId: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "光熱費",
            sortOrder: 1,
            isDefault: true
        ),
        Category(
            id: UUID(uuidString: "0D8C77C2-B4C9-4617-9E0D-AE14D149C9B6")!,
            pocketId: UUID(uuidString: "A2E2E92C-A4F9-4B6C-BB9F-A928A84E5B8C")!,
            name: "日用品",
            sortOrder: 2,
            isDefault: true
        ),
    ]
}
