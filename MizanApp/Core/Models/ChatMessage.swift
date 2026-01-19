//
//  ChatMessage.swift
//  Mizan
//
//  Models for AI chat-to-task feature
//

import Foundation

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    var extractedTask: ExtractedTaskData?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        extractedTask: ExtractedTaskData? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.extractedTask = extractedTask
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Extracted Task Data

struct ExtractedTaskData: Codable, Equatable {
    var title: String
    var notes: String?
    var duration: Int
    var category: String?
    var scheduledDate: String?
    var scheduledTime: String?
    var recurrence: RecurrenceData?
    var confidence: Double
    var clarificationNeeded: String?

    struct RecurrenceData: Codable, Equatable {
        var frequency: String // daily, weekly, monthly
        var interval: Int
        var daysOfWeek: [Int]?
    }

    init(
        title: String,
        notes: String? = nil,
        duration: Int = 30,
        category: String? = nil,
        scheduledDate: String? = nil,
        scheduledTime: String? = nil,
        recurrence: RecurrenceData? = nil,
        confidence: Double = 0.8,
        clarificationNeeded: String? = nil
    ) {
        self.title = title
        self.notes = notes
        self.duration = duration
        self.category = category
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.recurrence = recurrence
        self.confidence = confidence
        self.clarificationNeeded = clarificationNeeded
    }

    // MARK: - Convert to Task

    func toTask() -> Task {
        // Determine category
        let taskCategory: TaskCategory
        if let categoryStr = category?.lowercased() {
            switch categoryStr {
            case "work": taskCategory = .work
            case "personal": taskCategory = .personal
            case "study": taskCategory = .study
            case "health": taskCategory = .health
            case "social": taskCategory = .social
            case "worship": taskCategory = .worship
            default: taskCategory = .personal
            }
        } else {
            taskCategory = .personal
        }

        let task = Task(
            title: title,
            duration: duration,
            category: taskCategory,
            notes: notes
        )

        // Set scheduled date and time
        if let dateStr = scheduledDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]

            if let date = dateFormatter.date(from: dateStr) {
                task.scheduledDate = date

                // Set time if available
                if let timeStr = scheduledTime {
                    let timeComponents = timeStr.split(separator: ":")
                    if timeComponents.count >= 2,
                       let hour = Int(timeComponents[0]),
                       let minute = Int(timeComponents[1]) {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
                        components.hour = hour
                        components.minute = minute
                        if let fullDate = Calendar.current.date(from: components) {
                            task.scheduledStartTime = fullDate
                        }
                    }
                }
            }
        }

        // Set recurrence if available
        if let recurrenceData = recurrence {
            let frequency: RecurrenceRule.Frequency
            switch recurrenceData.frequency.lowercased() {
            case "daily": frequency = .daily
            case "weekly": frequency = .weekly
            case "monthly": frequency = .monthly
            default: frequency = .daily
            }

            task.recurrenceRule = RecurrenceRule(
                frequency: frequency,
                interval: recurrenceData.interval,
                daysOfWeek: recurrenceData.daysOfWeek
            )
            task.isRecurring = true
        }

        return task
    }
}

// MARK: - AI API Message Format

struct AIMessage: Codable {
    let role: String
    let content: String

    init(role: String, content: String) {
        self.role = role
        self.content = content
    }

    init(from chatMessage: ChatMessage) {
        self.role = chatMessage.role.rawValue
        self.content = chatMessage.content
    }
}

// MARK: - AI Response Models

struct OpenAIResponse: Codable {
    let id: String
    let choices: [OpenAIChoice]
    let usage: OpenAIUsage?

    struct OpenAIChoice: Codable {
        let index: Int
        let message: OpenAIMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    struct OpenAIMessage: Codable {
        let role: String
        let content: String
    }

    struct OpenAIUsage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct ClaudeResponse: Codable {
    let id: String
    let content: [ClaudeContent]
    let stopReason: String?
    let usage: ClaudeUsage?

    struct ClaudeContent: Codable {
        let type: String
        let text: String
    }

    struct ClaudeUsage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case stopReason = "stop_reason"
        case usage
    }
}
