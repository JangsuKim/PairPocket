import Foundation
import SwiftData
import Testing
@testable import PairPocket

@MainActor
struct PersistenceRegressionTests {
    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: ExpenseRecord.self, PocketRecord.self, DeletedPocketRecord.self, CategoryRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    @Test(arguments: [([0], 2, [1, 0, 2, 3]), ([3], 1, [0, 3, 1, 2]), ([0, 2], 4, [1, 3, 0, 2])])
    func categoryMovePreservesDropPosition(indices: [Int], destination: Int, expected: [Int]) throws {
        let container = try container()
        let context = container.mainContext
        let pocketID = UUID()
        for index in 0..<4 {
            context.insert(CategoryRecord(category: Category(pocketId: pocketID, name: "\(index)", sortOrder: index)))
        }
        try context.save()
        let store = CategoryStore()
        try store.reload(from: context)
        try store.moveCategories(in: pocketID, fromOffsets: IndexSet(indices), toOffset: destination, in: context)
        #expect(store.categories(for: pocketID).map(\.name) == expected.map(String.init))
    }

    @Test func deletedFlagsAreRespectedWhenLoading() throws {
        let container = try container()
        let context = container.mainContext
        let entry = Expense(pocketId: UUID(), paymentSource: .host, amount: 100, date: Date(), isDeleted: true)
        let record = ExpenseRecord(entry: entry)
        context.insert(record)
        try context.save()
        #expect(record.deletedAt != nil)
        #expect(record.pocketEntry.isDeleted)
        let store = ExpenseStore()
        try store.reload(from: context)
        #expect(store.entries.count == 0)
    }
}
