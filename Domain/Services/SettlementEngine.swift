import Foundation

public enum SettlementEngine {
    public static func calculate(entries: [PocketEntry]) -> SettlementSummary {
        let unsettledEntries = entries.filter { !$0.isSettled }
        let unsettledExpenses = unsettledEntries.filter { $0.type == .expense }
        let unsettledDeposits = unsettledEntries.filter { $0.type == .deposit }

        var totalSpent = 0
        var totalDeposited = 0
        var currentBalance = 0
        var totalPaidByMemberA = 0
        var totalPaidByMemberB = 0
        var totalShareNumeratorA = 0
        var totalShareNumeratorB = 0

        for deposit in unsettledDeposits {
            totalDeposited += deposit.amount
            currentBalance += deposit.amount
        }

        for expense in unsettledExpenses {
            totalSpent += expense.amount

            // Aggregate proportional shares first and round once at the period level
            // to avoid accumulating per-expense rounding bias.
            if expense.paymentSource == .memberA || expense.paymentSource == .memberB {
                totalShareNumeratorA += expense.amount * expense.ratioA
                totalShareNumeratorB += expense.amount * expense.ratioB
            }

            switch expense.paymentSource {
            case .memberA:
                totalPaidByMemberA += expense.amount
            case .memberB:
                totalPaidByMemberB += expense.amount
            case .pocket:
                currentBalance -= expense.amount
            }
        }

        let totalShareOfMemberA = roundedShare(
            numerator: totalShareNumeratorA,
            otherNumerator: totalShareNumeratorB,
            totalPaid: totalPaidByMemberA,
            otherTotalPaid: totalPaidByMemberB,
            preferCurrentMemberOnFullTie: true
        )
        let totalShareOfMemberB = roundedShare(
            numerator: totalShareNumeratorB,
            otherNumerator: totalShareNumeratorA,
            totalPaid: totalPaidByMemberB,
            otherTotalPaid: totalPaidByMemberA,
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
            totalPaidByMemberA: totalPaidByMemberA,
            totalPaidByMemberB: totalPaidByMemberB,
            totalShareOfMemberA: totalShareOfMemberA,
            totalShareOfMemberB: totalShareOfMemberB
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
