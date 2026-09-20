import Foundation
import Testing
@testable import PairPocket

struct SettlementCalculatorTests {

    // MARK: - calculateSettlement (Direct Input)

    @Test func hostOverpaid_partnerPaysHost() {
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 8000,
            totalPaidByPartner: 2000,
            totalShareOfHost: 5000,
            totalShareOfPartner: 5000
        )
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 3000)
    }

    @Test func partnerOverpaid_hostPaysPartner() {
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 2000,
            totalPaidByPartner: 8000,
            totalShareOfHost: 5000,
            totalShareOfPartner: 5000
        )
        #expect(result.settlementPayer == .host)
        #expect(result.settlementReceiver == .partner)
        #expect(result.settlementAmount == 3000)
    }

    @Test func exactlyBalanced_zeroSettlement() {
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 5000,
            totalPaidByPartner: 5000,
            totalShareOfHost: 5000,
            totalShareOfPartner: 5000
        )
        #expect(result.settlementAmount == 0)
        #expect(result.settlementPayer == nil)
        #expect(result.settlementReceiver == nil)
    }

    @Test func allZeros_zeroSettlement() {
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 0,
            totalPaidByPartner: 0,
            totalShareOfHost: 0,
            totalShareOfPartner: 0
        )
        #expect(result.settlementAmount == 0)
        #expect(result.settlementPayer == nil)
        #expect(result.settlementReceiver == nil)
    }

    @Test func unevenRatio_correctDirection() {
        // 60:40 ratio, host paid everything
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 10000,
            totalPaidByPartner: 0,
            totalShareOfHost: 6000,
            totalShareOfPartner: 4000
        )
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 4000)
    }

    @Test func smallDifference_1yenSettlement() {
        let result = SettlementCalculator.calculateSettlement(
            totalPaidByHost: 501,
            totalPaidByPartner: 500,
            totalShareOfHost: 500,
            totalShareOfPartner: 501
        )
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 1)
    }

    // MARK: - calculate(input:) Produces Correct Summary

    @Test func summaryInput_allFieldsPassedThrough() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)

        let result = SettlementCalculator.calculate(input: .init(
            periodStart: start,
            periodEnd: end,
            totalSpent: 10000,
            totalDeposited: 5000,
            currentBalance: 2000,
            expenseCount: 5,
            totalPaidByHost: 7000,
            totalPaidByPartner: 3000,
            totalShareOfHost: 6000,
            totalShareOfPartner: 4000
        ))
        #expect(result.periodStart == start)
        #expect(result.periodEnd == end)
        #expect(result.totalSpent == 10000)
        #expect(result.totalDeposited == 5000)
        #expect(result.currentBalance == 2000)
        #expect(result.expenseCount == 5)
        #expect(result.totalPaidByHost == 7000)
        #expect(result.totalPaidByPartner == 3000)
        #expect(result.totalShareOfHost == 6000)
        #expect(result.totalShareOfPartner == 4000)
        #expect(result.settlementPayer == .partner)
        #expect(result.settlementReceiver == .host)
        #expect(result.settlementAmount == 1000)
    }
}
