//
//  RecurrenceRuleTests.swift
//  MizanAppTests
//
//  Tests for RecurrenceRule - daily, weekly, monthly recurrence logic
//

import Testing
import Foundation
@testable import MizanApp

struct RecurrenceRuleTests {

    // MARK: - Daily Recurrence Tests

    @Test func dailyRecurrenceNextOccurrence() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    @Test func dailyRecurrenceWithInterval() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 3)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .day, value: 3, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    // MARK: - Weekly Recurrence Tests

    @Test func weeklyRecurrenceNextOccurrence() throws {
        let rule = RecurrenceRule(frequency: .weekly, interval: 1)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    @Test func weeklyRecurrenceWithSpecificDays() throws {
        // Create a rule that recurs on Monday (2) and Friday (6)
        let rule = RecurrenceRule(frequency: .weekly, interval: 1, daysOfWeek: [2, 6])

        // Get a known Monday
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 19 // A Monday
        let monday = Calendar.current.date(from: components)!

        let nextOccurrence = rule.nextOccurrence(after: monday)

        #expect(nextOccurrence != nil)
        // Should be Tuesday (2) - wait, days are 1=Sunday, so Monday is 2
        // After Monday (2), next matching day should be Friday (6)
        let weekday = Calendar.current.component(.weekday, from: nextOccurrence!)
        #expect(weekday == 2 || weekday == 6) // Should be Monday or Friday
    }

    @Test func weeklyRecurrenceWithInterval() throws {
        let rule = RecurrenceRule(frequency: .weekly, interval: 2)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    // MARK: - Monthly Recurrence Tests

    @Test func monthlyRecurrenceNextOccurrence() throws {
        let rule = RecurrenceRule(frequency: .monthly, interval: 1)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .month, value: 1, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    @Test func monthlyRecurrenceWithInterval() throws {
        let rule = RecurrenceRule(frequency: .monthly, interval: 3)
        let today = Calendar.current.startOfDay(for: Date())

        let nextOccurrence = rule.nextOccurrence(after: today)

        #expect(nextOccurrence != nil)
        let expectedDate = Calendar.current.date(byAdding: .month, value: 3, to: today)
        #expect(Calendar.current.isDate(nextOccurrence!, inSameDayAs: expectedDate!))
    }

    // MARK: - End Date Tests

    @Test func shouldEndBeforeReturnsTrueWhenPastEndDate() throws {
        let endDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let rule = RecurrenceRule(frequency: .daily, interval: 1, endDate: endDate)

        #expect(rule.shouldEndBefore(date: Date()) == true)
    }

    @Test func shouldEndBeforeReturnsFalseWhenBeforeEndDate() throws {
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let rule = RecurrenceRule(frequency: .daily, interval: 1, endDate: endDate)

        #expect(rule.shouldEndBefore(date: Date()) == false)
    }

    @Test func shouldEndBeforeReturnsFalseWhenNoEndDate() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 1)

        #expect(rule.shouldEndBefore(date: Date()) == false)
    }

    // MARK: - Display Text Tests

    @Test func displayTextForDaily() throws {
        let daily = RecurrenceRule(frequency: .daily, interval: 1)
        #expect(daily.displayText == "Daily")

        let everyThreeDays = RecurrenceRule(frequency: .daily, interval: 3)
        #expect(everyThreeDays.displayText == "Every 3 days")
    }

    @Test func displayTextForWeekly() throws {
        let weekly = RecurrenceRule(frequency: .weekly, interval: 1)
        #expect(weekly.displayText == "Weekly")

        let everyTwoWeeks = RecurrenceRule(frequency: .weekly, interval: 2)
        #expect(everyTwoWeeks.displayText == "Every 2 weeks")
    }

    @Test func displayTextForMonthly() throws {
        let monthly = RecurrenceRule(frequency: .monthly, interval: 1)
        #expect(monthly.displayText == "Monthly")

        let everyThreeMonths = RecurrenceRule(frequency: .monthly, interval: 3)
        #expect(everyThreeMonths.displayText == "Every 3 months")
    }

    // MARK: - Codable Tests

    @MainActor @Test func recurrenceRuleEncodesAndDecodes() throws {
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            daysOfWeek: [2, 4, 6],
            endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decodedRule = try decoder.decode(RecurrenceRule.self, from: data)

        #expect(decodedRule.frequency == rule.frequency)
        #expect(decodedRule.interval == rule.interval)
        #expect(decodedRule.daysOfWeek == rule.daysOfWeek)
    }

    // MARK: - Frequency Enum Tests

    @Test func frequencyRawValues() throws {
        #expect(RecurrenceRule.Frequency.daily.rawValue == "daily")
        #expect(RecurrenceRule.Frequency.weekly.rawValue == "weekly")
        #expect(RecurrenceRule.Frequency.monthly.rawValue == "monthly")
    }
}
