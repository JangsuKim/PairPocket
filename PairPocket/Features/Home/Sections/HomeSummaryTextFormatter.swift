import Foundation

enum HomeSummaryTextFormatter {
    private static let summaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let yenNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func summaryTitle(label: String, date: Date = Date()) -> String {
        "\(summaryDateFormatter.string(from: date)) \(label)"
    }

    static func yenAmountText(_ amount: Int) -> String {
        let formatted = yenNumberFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }
}
