enum SettlementResultPresenter {
    static func signedAmount(for summary: SettlementSummary) -> Int? {
        if summary.settlementAmount == 0 {
            return 0
        }

        guard let payer = summary.settlementPayer,
              let receiver = summary.settlementReceiver else {
            return nil
        }

        if payer == .host && receiver == .partner {
            return summary.settlementAmount
        }
        if payer == .partner && receiver == .host {
            return -summary.settlementAmount
        }
        return nil
    }

    static func arrowAssetName(for signedAmount: Int) -> String {
        if signedAmount > 0 {
            return "SettlementArrowHostToPartner"
        }
        if signedAmount < 0 {
            return "SettlementArrowPartnerToHost"
        }
        return "SettlementArrowBidirectional"
    }
}
