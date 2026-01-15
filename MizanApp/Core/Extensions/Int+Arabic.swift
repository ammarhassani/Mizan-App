//
//  Int+Arabic.swift
//  Mizan
//
//  Arabic pluralization helper for proper grammatical forms.
//  Arabic has three forms: singular (1), dual (2), and plural (3-10), then singular again (11+)
//

import Foundation

extension Int {
    /// Returns properly pluralized Arabic time unit
    /// - Parameters:
    ///   - singular: Singular form (ساعة)
    ///   - dual: Dual form (ساعتان) - optional
    ///   - plural: Plural form (ساعات)
    func arabicTimeUnit(singular: String, dual: String? = nil, plural: String) -> String {
        switch self {
        case 0: return plural  // "0 ساعات"
        case 1: return singular  // "ساعة"
        case 2: return dual ?? singular  // "ساعتان"
        case 3...10: return plural  // "ساعات"
        default: return singular  // "11+ ساعة"
        }
    }

    /// Arabic plural form for hours (ساعة/ساعتان/ساعات)
    var arabicHours: String {
        arabicTimeUnit(singular: "ساعة", dual: "ساعتان", plural: "ساعات")
    }

    /// Arabic plural form for minutes (دقيقة/دقيقتان/دقائق)
    var arabicMinutes: String {
        arabicTimeUnit(singular: "دقيقة", dual: "دقيقتان", plural: "دقائق")
    }

    /// Arabic plural form for seconds (ثانية/ثانيتان/ثواني)
    var arabicSeconds: String {
        arabicTimeUnit(singular: "ثانية", dual: "ثانيتان", plural: "ثواني")
    }

    /// Arabic plural form for days (يوم/يومان/أيام)
    var arabicDays: String {
        arabicTimeUnit(singular: "يوم", dual: "يومان", plural: "أيام")
    }

    /// Arabic plural form for rakaat (ركعة/ركعتان/ركعات)
    var arabicRakaat: String {
        arabicTimeUnit(singular: "ركعة", dual: "ركعتان", plural: "ركعات")
    }
}
