import SwiftUI

enum MoneyValueStyle {
    static let negativeValueColor = Color(red: 0.86, green: 0.48, blue: 0.50)
    static let positiveValueColor = Color(red: 0.38, green: 0.76, blue: 0.64)

    static func color(forSignedAmount amount: Int) -> Color {
        if amount < 0 {
            return negativeValueColor
        }
        if amount > 0 {
            return positiveValueColor
        }
        return .primary
    }

    static func color(for entryType: PocketEntryType) -> Color {
        switch entryType {
        case .expense:
            return negativeValueColor
        case .deposit:
            return positiveValueColor
        }
    }

    static func color(forExpenseAmount amount: Int) -> Color {
        amount > 0 ? negativeValueColor : .primary
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
