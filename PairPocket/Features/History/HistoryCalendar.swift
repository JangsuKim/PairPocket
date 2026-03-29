import Foundation

enum HistoryCalendar {
    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    static var shortWeekdaySymbols: [String] {
        calendar.veryShortStandaloneWeekdaySymbols
    }

    static func dayStart(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func monthStart(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    static func monthOffset(from date: Date, by value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: monthStart(for: date)) ?? date
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    static func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    static func monthCells(for monthStart: Date) -> [MonthCell] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }

        let firstWeekdayOfMonth = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekdayOfMonth - calendar.firstWeekday + 7) % 7

        var cells = (0..<offset).map { _ in MonthCell(date: nil) }

        for day in dayRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                cells.append(MonthCell(date: date))
            }
        }

        let trailingCount = (7 - (cells.count % 7)) % 7
        if trailingCount > 0 {
            cells.append(contentsOf: (0..<trailingCount).map { _ in MonthCell(date: nil) })
        }

        return cells
    }
}
