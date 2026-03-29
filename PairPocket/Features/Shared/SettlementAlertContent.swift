import Foundation

enum SettlementAlertKind {
    case confirmation
    case zeroAmount
}

enum SettlementAlertContent {
    static let confirmationTitle = "精算を完了しますか？"
    static let confirmationMessage = "精算完了にすると、対象の未精算履歴はすべて精算済みになります。"
    static let zeroAmountTitle = "精算する金額がありません"
    static let zeroAmountMessage = "現在、精算対象の未精算金額はありません。"
    static let cancelButtonTitle = "キャンセル"
    static let confirmButtonTitle = "精算完了"
    static let okButtonTitle = "OK"

    static func kind(for settlementAmount: Int) -> SettlementAlertKind {
        settlementAmount > 0 ? .confirmation : .zeroAmount
    }
}
