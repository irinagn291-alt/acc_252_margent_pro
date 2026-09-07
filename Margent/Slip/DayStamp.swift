import Foundation

/// Role: Slip. Day stamps are Int in YYYYMMDD form. Calendar.current start-of-day is a later display concern.
enum DayStamp: Sendable {
    static func yyyyMMdd(from date: Date, calendar: Calendar) -> Int {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return year * 10_000 + month * 100 + day
    }
}
