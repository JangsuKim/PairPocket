import Foundation

enum HomeSummaryTextFormatter {
    private static let summaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let periodDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    static func summaryTitle(label: String, date: Date = Date()) -> String {
        "\(summaryDateFormatter.string(from: date)) \(label)"
    }

    static func yenAmountText(_ amount: Int) -> String {
        YenFormatter.yen(amount)
    }

    static func summaryPeriodText(startDate: Date, endDate: Date, count: Int) -> String {
        "\(periodDateFormatter.string(from: startDate)) 〜 \(periodDateFormatter.string(from: endDate)) (\(count)件)"
    }
}
