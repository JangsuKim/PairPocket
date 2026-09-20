import Foundation

enum YenFormatter {
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.numberStyle = .decimal
        return formatter
    }()

    static func yen(_ amount: Int) -> String {
        let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formatted)"
    }

    static func yenWithSuffix(_ amount: Int) -> String {
        let formatted = numberFormatter.string(from: NSNumber(value: amount)) ?? "0"
        return "\(formatted)円"
    }
}
