import Foundation
import SwiftData

@Model
final class CategoryRecord {
    var id: UUID
    var pocketId: UUID
    var name: String
    var icon: String?
    var sortOrder: Int
    var isDefault: Bool
    var isActive: Bool

    init(
        id: UUID = UUID(),
        pocketId: UUID,
        name: String,
        icon: String? = nil,
        sortOrder: Int = 0,
        isDefault: Bool = false,
        isActive: Bool = true
    ) {
        self.id = id
        self.pocketId = pocketId
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.isActive = isActive
    }
}

extension CategoryRecord {
    convenience init(category: Category) {
        self.init(
            id: category.id,
            pocketId: category.pocketId,
            name: category.name,
            icon: category.icon,
            sortOrder: category.sortOrder,
            isDefault: category.isDefault,
            isActive: category.isActive
        )
    }

    var category: Category {
        Category(
            id: id,
            pocketId: pocketId,
            name: name,
            icon: icon,
            sortOrder: sortOrder,
            isDefault: isDefault,
            isActive: isActive
        )
    }
}
