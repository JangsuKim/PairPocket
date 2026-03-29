import SwiftUI

enum MoneyValueStyle {
    static func color(forSignedAmount amount: Int) -> Color {
        if amount < 0 {
            return .red
        }
        if amount > 0 {
            return .green
        }
        return .primary
    }

    static func color(for entryType: PocketEntryType) -> Color {
        switch entryType {
        case .expense:
            return .red
        case .deposit:
            return .green
        }
    }

    static func color(forExpenseAmount amount: Int) -> Color {
        amount > 0 ? .red : .primary
    }

    static func colorForPocketDisplay(mode: PocketMode, displayedAmount: Int, currentBalance: Int) -> Color {
        switch mode {
        case .settlementOnly:
            return color(forExpenseAmount: displayedAmount)
        case .sharedManagement:
            if currentBalance > 0 {
                return color(forSignedAmount: displayedAmount)
            }
            return color(forExpenseAmount: displayedAmount)
        }
    }
}
