import Foundation
import Testing
@testable import PairPocket

struct SettlementEngineTests {

    @Test func sharedBalanceDoesNotChangeAfterSettlement() {
        let deposit = makeEntry(type: .deposit, amount: 5000)
        let expense = makeEntry(paymentSource: .pocket, amount: 1200)
        let settled = SettlementExecutor.markExpensesSettled(
            expenses: [expense], settlementId: UUID(), settledAt: Date()
        )
        #expect(SettlementEngine.currentPocketBalance(entries: [deposit, expense]) == 3800)
        #expect(SettlementEngine.currentPocketBalance(entries: [deposit] + settled) == 3800)
    }

    @Test func sharedBalanceExcludesDeletedAndPersonalPayments() {
        var deleted = makeEntry(type: .deposit, amount: 2000)
        deleted.isDeleted = true
        var deletedExpense = makeEntry(paymentSource: .pocket, amount: 500)
        deletedExpense.deletedAt = Date()
        let entries = [makeEntry(type: .deposit, amount: 1000), makeEntry(amount: 300), deleted, deletedExpense]
        #expect(SettlementEngine.currentPocketBalance(entries: entries) == 1000)
    }

    @Test func deletedEntriesDoNotAffectSettlement() {
        var deletedExpense = makeEntry(amount: 1000)
        deletedExpense.isDeleted = true
        var deletedDeposit = makeEntry(type: .deposit, amount: 2000)
        deletedDeposit.deletedAt = Date()
        let result = SettlementEngine.calculate(entries: [deletedExpense, deletedDeposit])
        #expect(result.totalSpent == 0)
        #expect(result.totalDeposited == 0)
        #expect(result.expenseCount == 0)
        #expect(result.settlementAmount == 0)
    }

    private let testPocketId = UUID()

    private func makeEntry(
        type: PocketEntryType = .expense,
        paymentSource: PaymentSource = .host,
        amount: Int,
        ratioHost: Int = 50,
        ratioPartner: Int = 50,
        date: Date = Date(),
        isSettled: Bool = false
    ) -> PocketEntry {
        PocketEntry(
            pocketId: testPocketId,
            type: type,
            paymentSource: paymentSource,
            amount: amount,
            ratioHost: ratioHost,
            ratioPartner: ratioPartner,
            date: date,
            isSettled: isSettled
        )
    }

    // MARK: - Empty / No-Op Cases

    @Test func emptyEntries_returnsZeroSettlement() {
        let result = SettlementEngine.calculate(entries: [])
        #expect(result.settlementAmount == 0)
        #expect(result.settlementPayer == nil)
        #expect(result.settlementReceiver == nil)
        #expect(result.expenseCount == 0)
        #expect(result.totalSpent == 0)
        #expect(result.totalDeposited == 0)
    }

    @Test func allSettledEntries_returnsZeroSettlement() {
        let entries = [
            makeEntry(amount: 1000, isSettled: true),
            makeEntry(paymentSource: .partner, amount: 500, isSettled: true)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementAmount == 0)
        #expect(result.expenseCount == 0)
        #expect(result.totalSpent == 0)
    }

    // MARK: - Single Expense, Equal Ratio (50:50)

    @Test func singleExpense_hostPays_equalRatio() {
        let entries = [makeEntry(amount: 1000)]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 500)
        #expect(result.totalPaidByHost == 1000)
        #expect(result.totalPaidByPartner == 0)
        #expect(result.totalSpent == 1000)
        #expect(result.expenseCount == 1)
    }

    @Test func singleExpense_partnerPays_equalRatio() {
        let entries = [makeEntry(paymentSource: .partner, amount: 1000)]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementPayer == .host)
        #expect(result.settlementReceiver == .partner)
        #expect(result.settlementAmount == 500)
        #expect(result.totalPaidByHost == 0)
        #expect(result.totalPaidByPartner == 1000)
    }

    // MARK: - Equal Payments Cancel Out

    @Test func equalPayments_equalRatio_zeroSettlement() {
        let entries = [
            makeEntry(amount: 1000),
            makeEntry(paymentSource: .partner, amount: 1000)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementAmount == 0)
        #expect(result.settlementPayer == nil)
        #expect(result.settlementReceiver == nil)
    }

    // MARK: - Mixed Payments

    @Test func mixedPayments_equalRatio_netSettlement() {
        let entries = [
            makeEntry(amount: 3000),
            makeEntry(paymentSource: .partner, amount: 1000)
        ]
        // Total 4000, each should pay 2000
        // Host paid 3000 → overpaid 1000
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 1000)
        #expect(result.totalSpent == 4000)
    }

    // MARK: - Uneven Ratios

    @Test func singleExpense_hostPays_ratio60_40() {
        let entries = [makeEntry(amount: 1000, ratioHost: 60, ratioPartner: 40)]
        // Both remainders 0 → exact division, no rounding adjustment
        // hostShare = 600, partnerShare = 400
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 400)
        #expect(result.totalShareOfHost == 600)
        #expect(result.totalShareOfPartner == 400)
    }

    @Test func singleExpense_partnerPays_ratio70_30() {
        let entries = [makeEntry(paymentSource: .partner, amount: 1000, ratioHost: 70, ratioPartner: 30)]
        // Partner should pay 300, paid 1000 → overpaid 700
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.settlementPayer == .host)
        #expect(result.settlementReceiver == .partner)
        #expect(result.settlementAmount == 700)
    }

    @Test func multipleExpenses_unevenRatio_correctAggregation() {
        let entries = [
            makeEntry(amount: 5000, ratioHost: 60, ratioPartner: 40),
            makeEntry(paymentSource: .partner, amount: 3000, ratioHost: 60, ratioPartner: 40),
            makeEntry(amount: 2000, ratioHost: 60, ratioPartner: 40)
        ]
        // Total = 10000
        // Host paid: 7000, Partner paid: 3000
        // Host share: 6000, Partner share: 4000
        // Host net: 7000 - 6000 = 1000 overpaid
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalSpent == 10000)
        #expect(result.totalPaidByHost == 7000)
        #expect(result.totalPaidByPartner == 3000)
        #expect(result.totalShareOfHost == 6000)
        #expect(result.totalShareOfPartner == 4000)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 1000)
    }

    // MARK: - Rounding (Period-Level)

    @Test func oddAmount_equalRatio_roundsFairly() {
        let entries = [makeEntry(amount: 999)]
        // 999 * 50 = 49950 for each
        // baseShare = 499, remainder = 50
        // Equal remainder → host paid more → hostShare = 499, partnerShare = 500
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalShareOfHost == 499)
        #expect(result.totalShareOfPartner == 500)
        #expect(result.totalShareOfHost + result.totalShareOfPartner == 999)
        #expect(result.settlementAmount == 500)
    }

    @Test func oddAmount_unevenRatio_sumsToTotal() {
        let entries = [makeEntry(amount: 333, ratioHost: 60, ratioPartner: 40)]
        // hostNum = 333*60 = 19980 → base 199, rem 80
        // partnerNum = 333*40 = 13320 → base 133, rem 20
        // Host rem(80) > partner rem(20) → hostShare = 200, partnerShare = 133
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalShareOfHost == 200)
        #expect(result.totalShareOfPartner == 133)
        #expect(result.totalShareOfHost + result.totalShareOfPartner == 333)
    }

    @Test func multipleOddAmounts_periodLevelRounding_sumsCorrectly() {
        let entries = [
            makeEntry(amount: 999),
            makeEntry(amount: 999),
            makeEntry(amount: 999)
        ]
        // Total = 2997
        // hostNumerator = 999*50*3 = 149850 → base 1498, rem 50
        // partnerNumerator = 149850 → base 1498, rem 50
        // Equal remainder → host paid 2997 > partner paid 0 → hostShare = 1498
        // Partner share = 1499
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalShareOfHost + result.totalShareOfPartner == 2997)
        #expect(result.totalShareOfHost == 1498)
        #expect(result.totalShareOfPartner == 1499)
    }

    @Test func equalPayments_evenSplit_zeroSettlement() {
        // Both remainders 0 → exact division, shares equal paid amounts, no settlement
        let entries = [
            makeEntry(amount: 1001),
            makeEntry(paymentSource: .partner, amount: 1001)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalShareOfHost == 1001)
        #expect(result.totalShareOfPartner == 1001)
        #expect(result.settlementAmount == 0)
    }

    // MARK: - Pocket Payment Source

    @Test func pocketPayment_deductsFromBalance_noPersonalSettlement() {
        let entries = [makeEntry(paymentSource: .pocket, amount: 1000)]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalPaidByHost == 0)
        #expect(result.totalPaidByPartner == 0)
        #expect(result.currentBalance == -1000)
        #expect(result.totalSpent == 1000)
        #expect(result.settlementAmount == 0)
        #expect(result.settlementPayer == nil)
    }

    @Test func pocketPayment_doesNotAffectShareCalculation() {
        let entries = [
            makeEntry(paymentSource: .pocket, amount: 500),
            makeEntry(amount: 1000)
        ]
        // Pocket expense: 500 deducted from balance, no share calc
        // Host expense: 1000, share 500 each
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalShareOfHost == 500)
        #expect(result.totalShareOfPartner == 500)
        #expect(result.currentBalance == -500)
    }

    // MARK: - Deposits

    @Test func deposit_increasesBalance_notCountedAsExpense() {
        let entries = [makeEntry(type: .deposit, amount: 5000)]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalDeposited == 5000)
        #expect(result.currentBalance == 5000)
        #expect(result.expenseCount == 0)
        #expect(result.totalSpent == 0)
        #expect(result.settlementAmount == 0)
    }

    @Test func depositAndPocketExpense_balanceTracking() {
        let entries = [
            makeEntry(type: .deposit, amount: 5000),
            makeEntry(paymentSource: .pocket, amount: 3000)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalDeposited == 5000)
        #expect(result.currentBalance == 2000)
        #expect(result.totalSpent == 3000)
    }

    @Test func settledDeposit_isExcluded() {
        let entries = [
            makeEntry(type: .deposit, amount: 5000, isSettled: true),
            makeEntry(type: .deposit, amount: 2000, isSettled: false)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalDeposited == 2000)
        #expect(result.currentBalance == 2000)
    }

    // MARK: - Mixed Settled and Unsettled

    @Test func mixedSettledAndUnsettled_onlyCountsUnsettled() {
        let entries = [
            makeEntry(amount: 1000, isSettled: true),
            makeEntry(amount: 2000, isSettled: false)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.expenseCount == 1)
        #expect(result.totalSpent == 2000)
        #expect(result.totalPaidByHost == 2000)
    }

    // MARK: - Period Dates

    @Test func periodDates_reflectUnsettledEntriesOnly() {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let jan15 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!
        let feb1 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!

        let entries = [
            makeEntry(amount: 1000, date: jan1, isSettled: true),
            makeEntry(amount: 500, date: jan15),
            makeEntry(amount: 300, date: feb1)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.periodStart == jan15)
        #expect(result.periodEnd == feb1)
    }

    @Test func periodDates_includesDepositsInRange() {
        let calendar = Calendar.current
        let jan1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let mar1 = calendar.date(from: DateComponents(year: 2025, month: 3, day: 1))!

        let entries = [
            makeEntry(type: .deposit, amount: 5000, date: jan1),
            makeEntry(amount: 1000, date: mar1)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.periodStart == jan1)
        #expect(result.periodEnd == mar1)
    }

    // MARK: - Expense Count

    @Test func expenseCount_excludesDeposits() {
        let entries = [
            makeEntry(amount: 1000),
            makeEntry(type: .deposit, amount: 2000),
            makeEntry(paymentSource: .partner, amount: 500)
        ]
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.expenseCount == 2)
    }

    // MARK: - Comprehensive Scenarios

    @Test func realisticMonthlyScenario() {
        let entries = [
            makeEntry(amount: 4500, ratioHost: 55, ratioPartner: 45),
            makeEntry(paymentSource: .partner, amount: 2800, ratioHost: 55, ratioPartner: 45),
            makeEntry(amount: 1200, ratioHost: 55, ratioPartner: 45),
            makeEntry(paymentSource: .partner, amount: 3500, ratioHost: 55, ratioPartner: 45)
        ]
        // Total = 12000
        // Host paid: 4500 + 1200 = 5700
        // Partner paid: 2800 + 3500 = 6300
        // hostNumerator = 12000 * 55 = 660000 → share = 6600
        // partnerNumerator = 12000 * 45 = 540000 → share = 5400
        // Host net: 5700 - 6600 = -900 (underpaid)
        // Partner net: 6300 - 5400 = 900 (overpaid)
        // Host pays partner 900
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalSpent == 12000)
        #expect(result.totalShareOfHost == 6600)
        #expect(result.totalShareOfPartner == 5400)
        #expect(result.settlementPayer == .host)
        #expect(result.settlementReceiver == .partner)
        #expect(result.settlementAmount == 900)
    }

    @Test func sharedManagementScenario_depositsAndMixedPayments() {
        let entries = [
            makeEntry(type: .deposit, amount: 10000),
            makeEntry(paymentSource: .pocket, amount: 4000),
            makeEntry(amount: 3000),
            makeEntry(paymentSource: .partner, amount: 2000)
        ]
        // Deposits: 10000
        // Pocket expense: 4000, balance = 10000 - 4000 = 6000
        // Host expense: 3000, share 1500 each
        // Partner expense: 2000, share 1000 each
        // Total spent: 4000 + 3000 + 2000 = 9000
        // Host paid: 3000, Partner paid: 2000
        // Host share: (3000+2000)*50/100 = 2500
        // Partner share: 2500
        // Host net: 3000 - 2500 = 500 (overpaid)
        // Partner pays host 500
        let result = SettlementEngine.calculate(entries: entries)
        #expect(result.totalDeposited == 10000)
        #expect(result.currentBalance == 6000)
        #expect(result.totalSpent == 9000)
        #expect(result.totalPaidByHost == 3000)
        #expect(result.totalPaidByPartner == 2000)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 500)
    }
}
