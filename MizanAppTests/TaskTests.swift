//
//  TaskTests.swift
//  MizanAppTests
//
//  Tests for Task model - completion, scheduling, recurring instances
//

import Testing
import Foundation
@testable import MizanApp

struct TaskTests {

    // MARK: - Initialization Tests

    @Test func taskInitializesWithDefaults() throws {
        let task = Task(title: "Test Task")

        #expect(task.title == "Test Task")
        #expect(task.duration == 30)
        #expect(task.category == .personal)
        #expect(task.isCompleted == false)
        #expect(task.isRecurring == false)
        #expect(task.scheduledStartTime == nil)
        #expect(task.scheduledDate == nil)
        #expect(task.notes == nil)
        #expect(task.recurrenceRule == nil)
    }

    @Test func taskInitializesWithCustomValues() throws {
        let task = Task(
            title: "Work Meeting",
            duration: 60,
            category: .work,
            icon: "briefcase.fill",
            notes: "Important meeting"
        )

        #expect(task.title == "Work Meeting")
        #expect(task.duration == 60)
        #expect(task.category == .work)
        #expect(task.icon == "briefcase.fill")
        #expect(task.notes == "Important meeting")
    }

    @Test func taskHasUniqueId() throws {
        let task1 = Task(title: "Task 1")
        let task2 = Task(title: "Task 2")

        #expect(task1.id != task2.id)
    }

    // MARK: - Completion Tests

    @Test func markCompleteUpdatesState() throws {
        let task = Task(title: "Test Task")

        task.markComplete()

        #expect(task.isCompleted == true)
        #expect(task.completedAt != nil)
    }

    @Test func unmarkCompleteResetsState() throws {
        let task = Task(title: "Test Task")
        task.markComplete()

        task.unmarkComplete()

        #expect(task.isCompleted == false)
        #expect(task.completedAt == nil)
    }

    @Test func completeAndUncompleteAliases() throws {
        let task = Task(title: "Test Task")

        task.complete()
        #expect(task.isCompleted == true)

        task.uncomplete()
        #expect(task.isCompleted == false)
    }

    // MARK: - Scheduling Tests

    @Test func scheduleAtSetsTime() throws {
        let task = Task(title: "Test Task")
        let scheduleTime = Date()

        task.scheduleAt(time: scheduleTime)

        #expect(task.scheduledStartTime != nil)
        #expect(task.scheduledDate != nil)
        #expect(task.isScheduled == true)
        #expect(task.isInInbox == false)
    }

    @Test func moveToInboxClearsSchedule() throws {
        let task = Task(title: "Test Task")
        task.scheduleAt(time: Date())

        task.moveToInbox()

        #expect(task.scheduledStartTime == nil)
        #expect(task.scheduledDate == nil)
        #expect(task.isScheduled == false)
        #expect(task.isInInbox == true)
    }

    @Test func isInInboxWhenNotScheduled() throws {
        let task = Task(title: "Test Task")

        #expect(task.isInInbox == true)
        #expect(task.isScheduled == false)
    }

    // MARK: - End Time Calculation Tests

    @Test func endTimeCalculatesCorrectly() throws {
        let task = Task(title: "Test Task", duration: 30)
        let startTime = Date()
        task.scheduleAt(time: startTime)

        #expect(task.endTime != nil)

        let expectedEndTime = startTime.addingTimeInterval(30 * 60)
        let timeDifference = abs(task.endTime!.timeIntervalSince(expectedEndTime))
        #expect(timeDifference < 1) // Within 1 second
    }

    @Test func endTimeIsNilWhenNotScheduled() throws {
        let task = Task(title: "Test Task")

        #expect(task.endTime == nil)
    }

    // MARK: - Duration Tests

    @Test func updateDurationChangesValue() throws {
        let task = Task(title: "Test Task", duration: 30)

        task.updateDuration(60)

        #expect(task.duration == 60)
    }

    // MARK: - Title Tests

    @Test func updateTitleChangesValue() throws {
        let task = Task(title: "Original Title")

        task.updateTitle("New Title")

        #expect(task.title == "New Title")
    }

    // MARK: - Due Date Tests

    @Test func setDueDateAssignsValue() throws {
        let task = Task(title: "Test Task")
        let dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!

        task.setDueDate(dueDate)

        #expect(task.dueDate != nil)
    }

    @Test func setDueDateNilClearsValue() throws {
        let task = Task(title: "Test Task")
        task.setDueDate(Date())

        task.setDueDate(nil)

        #expect(task.dueDate == nil)
    }

    @Test func isOverdueWhenPastDueDate() throws {
        let task = Task(title: "Test Task")
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        task.setDueDate(pastDate)

        #expect(task.isOverdue == true)
    }

    @Test func isNotOverdueWhenNotDue() throws {
        let task = Task(title: "Test Task")
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        task.setDueDate(futureDate)

        #expect(task.isOverdue == false)
    }

    @Test func isNotOverdueWhenCompleted() throws {
        let task = Task(title: "Test Task")
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        task.setDueDate(pastDate)
        task.markComplete()

        #expect(task.isOverdue == false)
    }

    @Test func isDueSoonWithin24Hours() throws {
        let task = Task(title: "Test Task")
        let soonDate = Calendar.current.date(byAdding: .hour, value: 12, to: Date())!
        task.setDueDate(soonDate)

        #expect(task.isDueSoon == true)
    }

    @Test func isNotDueSoonBeyond24Hours() throws {
        let task = Task(title: "Test Task")
        let laterDate = Calendar.current.date(byAdding: .hour, value: 36, to: Date())!
        task.setDueDate(laterDate)

        #expect(task.isDueSoon == false)
    }

    // MARK: - Updated At Tests

    @Test func updatedAtChangesOnModification() throws {
        let task = Task(title: "Test Task")
        let initialUpdatedAt = task.updatedAt

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.1)

        task.updateTitle("New Title")

        #expect(task.updatedAt > initialUpdatedAt)
    }

    // MARK: - Recurring Instance Tests

    @Test func dismissRecurringInstanceAddsDate() throws {
        let task = Task(title: "Recurring Task")
        task.isRecurring = true
        task.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
        let dismissDate = Date()

        task.dismissRecurringInstance(for: dismissDate)

        #expect(task.dismissedInstanceDates != nil)
        #expect(task.dismissedInstanceDates?.count == 1)
    }

    @Test func isInstanceDismissedReturnsTrueForDismissedDate() throws {
        let task = Task(title: "Recurring Task")
        task.isRecurring = true
        let dismissDate = Date()
        task.dismissRecurringInstance(for: dismissDate)

        #expect(task.isInstanceDismissed(for: dismissDate) == true)
    }

    @Test func isInstanceDismissedReturnsFalseForNonDismissedDate() throws {
        let task = Task(title: "Recurring Task")
        task.isRecurring = true

        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        #expect(task.isInstanceDismissed(for: futureDate) == false)
    }

    @Test func dismissedInstanceDatesDoesNotDuplicateSameDay() throws {
        let task = Task(title: "Recurring Task")
        task.isRecurring = true
        let date = Date()

        task.dismissRecurringInstance(for: date)
        task.dismissRecurringInstance(for: date)

        #expect(task.dismissedInstanceDates?.count == 1)
    }

    // MARK: - Create Recurring Instance Tests

    @Test func createRecurringInstanceCopiesBasicProperties() throws {
        let parentTask = Task(
            title: "Daily Exercise",
            duration: 45,
            category: .health,
            icon: "figure.run",
            notes: "Morning workout"
        )
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)

        let instanceDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        #expect(instance.title == parentTask.title)
        #expect(instance.duration == parentTask.duration)
        #expect(instance.category == parentTask.category)
        #expect(instance.icon == parentTask.icon)
        #expect(instance.notes == parentTask.notes)
    }

    @Test func createRecurringInstanceSetsParentId() throws {
        let parentTask = Task(title: "Recurring Task")
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)

        let instanceDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        #expect(instance.parentTaskId == parentTask.id)
        #expect(instance.isRecurring == true)
    }

    @Test func createRecurringInstanceSetsScheduledDate() throws {
        let parentTask = Task(title: "Recurring Task")
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)

        let instanceDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        #expect(Calendar.current.isDate(instance.scheduledDate!, inSameDayAs: instanceDate))
    }

    @Test func createRecurringInstancePreservesStartTime() throws {
        let parentTask = Task(title: "Recurring Task")
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)

        // Schedule parent at 9:00 AM today
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        let scheduledTime = Calendar.current.date(from: components)!
        parentTask.scheduleAt(time: scheduledTime)

        let instanceDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        // Instance should be scheduled at 9:00 AM on the instance date
        #expect(instance.scheduledStartTime != nil)
        let instanceHour = Calendar.current.component(.hour, from: instance.scheduledStartTime!)
        let instanceMinute = Calendar.current.component(.minute, from: instance.scheduledStartTime!)
        #expect(instanceHour == 9)
        #expect(instanceMinute == 0)
    }

    @Test func createRecurringInstanceHasNewId() throws {
        let parentTask = Task(title: "Recurring Task")
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)

        let instanceDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        #expect(instance.id != parentTask.id)
    }

    @Test func createRecurringInstanceIsNotCompleted() throws {
        let parentTask = Task(title: "Recurring Task")
        parentTask.isRecurring = true
        parentTask.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
        parentTask.markComplete()

        let instanceDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let instance = parentTask.createRecurringInstance(for: instanceDate)

        #expect(instance.isCompleted == false)
    }
}

// MARK: - TaskCategory Tests

struct TaskCategoryTests {

    @Test func allCategoriesExist() throws {
        #expect(TaskCategory.allCases.count == 6)
    }

    @Test func categoryRawValues() throws {
        #expect(TaskCategory.work.rawValue == "work")
        #expect(TaskCategory.personal.rawValue == "personal")
        #expect(TaskCategory.study.rawValue == "study")
        #expect(TaskCategory.health.rawValue == "health")
        #expect(TaskCategory.social.rawValue == "social")
        #expect(TaskCategory.worship.rawValue == "worship")
    }

    @Test func categoryHasArabicNames() throws {
        for category in TaskCategory.allCases {
            #expect(!category.nameArabic.isEmpty)
        }
    }

    @Test func categoryHasEnglishNames() throws {
        #expect(TaskCategory.work.nameEnglish == "Work")
        #expect(TaskCategory.personal.nameEnglish == "Personal")
        #expect(TaskCategory.study.nameEnglish == "Study")
        #expect(TaskCategory.health.nameEnglish == "Health")
        #expect(TaskCategory.social.nameEnglish == "Social")
        #expect(TaskCategory.worship.nameEnglish == "Worship")
    }

    @Test func categoryHasIcons() throws {
        for category in TaskCategory.allCases {
            #expect(!category.icon.isEmpty)
        }
    }

    @Test func categoryHasDefaultColorHex() throws {
        for category in TaskCategory.allCases {
            #expect(category.defaultColorHex.hasPrefix("#"))
            #expect(category.defaultColorHex.count == 7) // #RRGGBB
        }
    }

    @Test func categoryHasHints() throws {
        for category in TaskCategory.allCases {
            #expect(!category.hintArabic.isEmpty)
            #expect(!category.hintEnglish.isEmpty)
        }
    }
}
