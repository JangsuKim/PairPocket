import Foundation

enum HomeSummaryTextFormatter {
    private static let summaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    static func summaryTitle(label: String, date: Date = Date()) -> String {
        "\(summaryDateFormatter.string(from: date)) \(label)"
    }

    static func yenAmountText(_ amount: Int) -> String {
        YenFormatter.yen(amount)
    }
}
