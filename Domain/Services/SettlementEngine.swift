import Foundation

public enum SettlementEngine {
    public static func calculate(entries: [PocketEntry]) -> SettlementSummary {
        let unsettledEntries = entries.filter { !$0.isSettled }
        let unsettledExpenses = unsettledEntries.filter { $0.type == .expense }
        let unsettledDeposits = unsettledEntries.filter { $0.type == .deposit }

        var totalSpent = 0
        var totalDeposited = 0
        var currentBalance = 0
        var totalPaidByHost = 0
        var totalPaidByPartner = 0
        var totalShareNumeratorHost = 0
        var totalShareNumeratorPartner = 0

        for deposit in unsettledDeposits {
            totalDeposited += deposit.amount
            currentBalance += deposit.amount
        }

        for expense in unsettledExpenses {
            let rolePaymentSource = SettlementInterpretationBoundary.rolePaymentSource(for: expense)
            totalSpent += expense.amount

            // Aggregate proportional shares first and round once at the period level
            // to avoid accumulating per-expense rounding bias.
            if rolePaymentSource == .host || rolePaymentSource == .partner {
                totalShareNumeratorHost += expense.amount * expense.ratioHost
                totalShareNumeratorPartner += expense.amount * expense.ratioPartner
            }

            switch rolePaymentSource {
            case .host:
                totalPaidByHost += expense.amount
            case .partner:
                totalPaidByPartner += expense.amount
            case .pocket:
                currentBalance -= expense.amount
            }
        }

        let totalShareOfHost = roundedShare(
            numerator: totalShareNumeratorHost,
            otherNumerator: totalShareNumeratorPartner,
            totalPaid: totalPaidByHost,
            otherTotalPaid: totalPaidByPartner,
            preferCurrentMemberOnFullTie: true
        )
        let totalShareOfPartner = roundedShare(
            numerator: totalShareNumeratorPartner,
            otherNumerator: totalShareNumeratorHost,
            totalPaid: totalPaidByPartner,
            otherTotalPaid: totalPaidByHost,
            preferCurrentMemberOnFullTie: false
        )

        let periodStart = unsettledEntries.map(\.date).min() ?? Date.distantPast
        let periodEnd = unsettledEntries.map(\.date).max() ?? Date.distantPast

        return SettlementCalculator.calculate(input: .init(
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalSpent: totalSpent,
            totalDeposited: totalDeposited,
            currentBalance: currentBalance,
            expenseCount: unsettledExpenses.count,
            totalPaidByHost: totalPaidByHost,
            totalPaidByPartner: totalPaidByPartner,
            totalShareOfHost: totalShareOfHost,
            totalShareOfPartner: totalShareOfPartner
        ))
    }

    public static func calculate(expenses: [Expense]) -> SettlementSummary {
        calculate(entries: expenses)
    }

    private static func roundedShare(
        numerator: Int,
        otherNumerator: Int,
        totalPaid: Int,
        otherTotalPaid: Int,
        preferCurrentMemberOnFullTie: Bool
    ) -> Int {
        let baseShare = numerator / 100
        let remainder = numerator % 100
        let otherRemainder = otherNumerator % 100

        if remainder > otherRemainder {
            return baseShare + 1
        }

        if remainder < otherRemainder {
            return baseShare
        }

        if totalPaid < otherTotalPaid {
            return baseShare + 1
        }

        if totalPaid > otherTotalPaid {
            return baseShare
        }

        return preferCurrentMemberOnFullTie ? baseShare + 1 : baseShare
    }
}
