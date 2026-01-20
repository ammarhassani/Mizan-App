//
//  AITaskService.swift
//  Mizan
//
//  AI-powered task service with tool calling support for full app management
//

import Foundation
import Network
import os.log

// MARK: - AI Task Service Protocol

protocol AITaskServiceProtocol {
    func extractTask(from message: String, conversationHistory: [ChatMessage]) async throws -> ExtractedTaskData
    func processMessage(_ message: String, context: AIContext, conversationHistory: [ChatMessage]) async throws -> AIIntent
    var isAvailable: Bool { get }
    var currentProvider: String { get }
}

// MARK: - AI Task Service

final class AITaskService: AITaskServiceProtocol {
    private let config: AIConfiguration
    private let networkMonitor: NWPathMonitor
    private var isNetworkAvailable: Bool = true

    // API key storage (should be in Keychain in production)
    private var apiKeys: [String: String] = [:]

    init(config: AIConfiguration) {
        self.config = config

        // Monitor network connectivity
        self.networkMonitor = NWPathMonitor()
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .utility))
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Public Properties

    var isAvailable: Bool {
        isNetworkAvailable && hasValidAPIKey
    }

    var currentProvider: String {
        config.defaultProvider
    }

    private var hasValidAPIKey: Bool {
        apiKeys[config.defaultProvider] != nil
    }

    // MARK: - API Key Management

    func setAPIKey(_ key: String, for provider: String) {
        apiKeys[provider] = key
    }

    func getAPIKey(for provider: String) -> String? {
        apiKeys[provider]
    }

    func clearAPIKey(for provider: String) {
        apiKeys.removeValue(forKey: provider)
    }

    // MARK: - Task Extraction (Legacy V1)

    func extractTask(from message: String, conversationHistory: [ChatMessage]) async throws -> ExtractedTaskData {
        guard isNetworkAvailable else {
            throw AIError.noNetwork
        }

        guard let apiKey = apiKeys[config.defaultProvider] else {
            throw AIError.apiKeyMissing
        }

        guard let providerConfig = config.providers[config.defaultProvider] else {
            throw AIError.providerUnavailable(config.defaultProvider)
        }

        // Build messages for API
        let systemPrompt = buildTaskExtractionPrompt()
        var messages: [AIMessage] = []

        // Add conversation history (limited)
        let historyLimit = config.settings.maxMessagesInHistory
        let recentHistory = conversationHistory.suffix(historyLimit)
        for chatMessage in recentHistory {
            messages.append(AIMessage(from: chatMessage))
        }

        // Add current message
        messages.append(AIMessage(role: "user", content: message))

        // Make API call based on provider
        let responseContent: String
        switch config.defaultProvider {
        case "openai", "deepseek":
            responseContent = try await callOpenAICompatible(
                baseUrl: providerConfig.baseUrl,
                model: providerConfig.model,
                messages: messages,
                systemPrompt: systemPrompt,
                apiKey: apiKey,
                maxTokens: providerConfig.maxTokens,
                temperature: providerConfig.temperature
            )
        case "claude":
            responseContent = try await callClaude(
                baseUrl: providerConfig.baseUrl,
                model: providerConfig.model,
                messages: messages,
                systemPrompt: systemPrompt,
                apiKey: apiKey,
                maxTokens: providerConfig.maxTokens,
                temperature: providerConfig.temperature,
                anthropicVersion: providerConfig.anthropicVersion ?? "2023-06-01"
            )
        default:
            throw AIError.providerUnavailable(config.defaultProvider)
        }

        // Parse response
        return try parseTaskFromResponse(responseContent)
    }

    // MARK: - Process Message with Tool Calling (V2)

    func processMessage(_ message: String, context: AIContext, conversationHistory: [ChatMessage]) async throws -> AIIntent {
        guard isNetworkAvailable else {
            throw AIError.noNetwork
        }

        guard let apiKey = apiKeys[config.defaultProvider] else {
            throw AIError.apiKeyMissing
        }

        guard let providerConfig = config.providers[config.defaultProvider] else {
            throw AIError.providerUnavailable(config.defaultProvider)
        }

        // Build system prompt with context
        let systemPrompt = buildAgentSystemPrompt(with: context)

        // Build messages
        var messages: [AIMessage] = []

        // Add conversation history (limited)
        let historyLimit = config.settings.maxMessagesInHistory
        let recentHistory = conversationHistory.suffix(historyLimit)
        for chatMessage in recentHistory {
            messages.append(AIMessage(from: chatMessage))
        }

        // Add current message
        messages.append(AIMessage(role: "user", content: message))

        // Make API call with tools
        let toolCallResult: ToolCallResult
        switch config.defaultProvider {
        case "openai", "deepseek":
            toolCallResult = try await callOpenAIWithTools(
                baseUrl: providerConfig.baseUrl,
                model: providerConfig.model,
                messages: messages,
                systemPrompt: systemPrompt,
                apiKey: apiKey,
                maxTokens: providerConfig.maxTokens,
                temperature: providerConfig.temperature,
                tools: config.tools
            )
        case "claude":
            toolCallResult = try await callClaudeWithTools(
                baseUrl: providerConfig.baseUrl,
                model: providerConfig.model,
                messages: messages,
                systemPrompt: systemPrompt,
                apiKey: apiKey,
                maxTokens: providerConfig.maxTokens,
                temperature: providerConfig.temperature,
                anthropicVersion: providerConfig.anthropicVersion ?? "2023-06-01",
                tools: config.tools
            )
        default:
            throw AIError.providerUnavailable(config.defaultProvider)
        }

        // Parse tool call into intent
        return try parseToolCallToIntent(toolCallResult)
    }

    // MARK: - Private Methods

    /// Build system prompt for legacy task extraction (V1)
    private func buildTaskExtractionPrompt() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = dateFormatter.string(from: Date())
        let timezone = TimeZone.current.identifier

        // Use Arabic prompt (primary language for the app)
        var prompt = config.taskExtraction.systemPromptArabic
        prompt = prompt.replacingOccurrences(of: "{{currentDate}}", with: currentDate)
        prompt = prompt.replacingOccurrences(of: "{{timezone}}", with: timezone)

        return prompt
    }

    /// Build system prompt for AI agent with full context (V2)
    private func buildAgentSystemPrompt(with context: AIContext) -> String {
        // Get the context as a formatted string
        let contextPrompt = context.toPromptString()

        // Use Arabic system prompt with context injection
        var prompt = config.systemPrompt.arabic
        prompt = prompt.replacingOccurrences(of: "{{CONTEXT}}", with: contextPrompt)

        return prompt
    }

    private func callOpenAICompatible(
        baseUrl: String,
        model: String,
        messages: [AIMessage],
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int,
        temperature: Double
    ) async throws -> String {
        guard let url = URL(string: "\(baseUrl)/chat/completions") else {
            throw AIError.invalidConfiguration
        }

        // Build request body
        var allMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for msg in messages {
            allMessages.append(["role": msg.role, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = TimeInterval(config.settings.requestTimeoutSeconds)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AIError.apiKeyInvalid
        case 429:
            throw AIError.rateLimited(retryAfter: 30)
        default:
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return content
    }

    private func callClaude(
        baseUrl: String,
        model: String,
        messages: [AIMessage],
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int,
        temperature: Double,
        anthropicVersion: String
    ) async throws -> String {
        guard let url = URL(string: "\(baseUrl)/messages") else {
            throw AIError.invalidConfiguration
        }

        // Build messages for Claude (no system role in messages array)
        var claudeMessages: [[String: String]] = []
        for msg in messages {
            claudeMessages.append(["role": msg.role, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": claudeMessages
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = TimeInterval(config.settings.requestTimeoutSeconds)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AIError.apiKeyInvalid
        case 429:
            throw AIError.rateLimited(retryAfter: 30)
        default:
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let content = claudeResponse.content.first?.text else {
            throw AIError.emptyResponse
        }

        return content
    }

    // MARK: - Tool Calling API Methods

    private func callOpenAIWithTools(
        baseUrl: String,
        model: String,
        messages: [AIMessage],
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int,
        temperature: Double,
        tools: [AITool]
    ) async throws -> ToolCallResult {
        guard let url = URL(string: "\(baseUrl)/chat/completions") else {
            throw AIError.invalidConfiguration
        }

        // Build request body with tools
        var allMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for msg in messages {
            allMessages.append(["role": msg.role, "content": msg.content])
        }

        // Convert tools to API format
        let toolsArray = tools.map { tool -> [String: Any] in
            return [
                "type": "function",
                "function": [
                    "name": tool.function.name,
                    "description": tool.function.description,
                    "parameters": tool.function.parameters
                ]
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": allMessages,
            "max_tokens": maxTokens,
            "temperature": temperature,
            "tools": toolsArray,
            "tool_choice": "auto"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = TimeInterval(config.settings.requestTimeoutSeconds)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AIError.apiKeyInvalid
        case 429:
            throw AIError.rateLimited(retryAfter: 30)
        default:
            MizanLogger.shared.lifecycle.error("HTTP error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                MizanLogger.shared.lifecycle.debug("Error response: \(errorString)")
            }
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse response with tool calls
        let openAIResponse = try JSONDecoder().decode(OpenAIToolResponse.self, from: data)

        guard let choice = openAIResponse.choices.first else {
            throw AIError.emptyResponse
        }

        // Check if there are tool calls
        if let toolCalls = choice.message.toolCalls, !toolCalls.isEmpty {
            guard let firstCall = toolCalls.first else {
                throw AIError.emptyResponse
            }
            return ToolCallResult(
                functionName: firstCall.function.name,
                arguments: firstCall.function.arguments,
                textContent: choice.message.content
            )
        }

        // If no tool call, check for content (might be a clarification or explanation)
        if let content = choice.message.content, !content.isEmpty {
            // AI responded with text instead of tool call - might need clarification
            return ToolCallResult(
                functionName: "text_response",
                arguments: "{}",
                textContent: content
            )
        }

        throw AIError.emptyResponse
    }

    private func callClaudeWithTools(
        baseUrl: String,
        model: String,
        messages: [AIMessage],
        systemPrompt: String,
        apiKey: String,
        maxTokens: Int,
        temperature: Double,
        anthropicVersion: String,
        tools: [AITool]
    ) async throws -> ToolCallResult {
        guard let url = URL(string: "\(baseUrl)/messages") else {
            throw AIError.invalidConfiguration
        }

        // Build messages for Claude
        var claudeMessages: [[String: String]] = []
        for msg in messages {
            claudeMessages.append(["role": msg.role, "content": msg.content])
        }

        // Convert tools to Claude format
        let claudeTools = tools.map { tool -> [String: Any] in
            return [
                "name": tool.function.name,
                "description": tool.function.description,
                "input_schema": tool.function.parameters
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": systemPrompt,
            "messages": claudeMessages,
            "tools": claudeTools
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = TimeInterval(config.settings.requestTimeoutSeconds)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw AIError.apiKeyInvalid
        case 429:
            throw AIError.rateLimited(retryAfter: 30)
        default:
            MizanLogger.shared.lifecycle.error("HTTP error: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                MizanLogger.shared.lifecycle.debug("Error response: \(errorString)")
            }
            throw AIError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse Claude response with tool use
        let claudeResponse = try JSONDecoder().decode(ClaudeToolResponse.self, from: data)

        // Look for tool use in content blocks
        for block in claudeResponse.content {
            if block.type == "tool_use", let name = block.name, let input = block.input {
                let argumentsData = try JSONSerialization.data(withJSONObject: input)
                let argumentsString = String(data: argumentsData, encoding: .utf8) ?? "{}"
                return ToolCallResult(
                    functionName: name,
                    arguments: argumentsString,
                    textContent: nil
                )
            }
        }

        // Check for text response
        for block in claudeResponse.content {
            if block.type == "text", let text = block.text {
                return ToolCallResult(
                    functionName: "text_response",
                    arguments: "{}",
                    textContent: text
                )
            }
        }

        throw AIError.emptyResponse
    }

    // MARK: - Intent Parsing

    private func parseToolCallToIntent(_ result: ToolCallResult) throws -> AIIntent {
        // Handle text response (no tool call)
        if result.functionName == "text_response" {
            if let text = result.textContent {
                // AI responded with text - treat as explanation or need clarification
                return .explain(topic: text)
            }
            throw AIError.parsingFailed
        }

        // Parse arguments
        guard let argsData = result.arguments.data(using: .utf8) else {
            throw AIError.parsingFailed
        }

        let args = try JSONSerialization.jsonObject(with: argsData) as? [String: Any] ?? [:]

        // Map function name to intent
        switch result.functionName {
        case "create_task":
            let taskData = try parseCreateTaskArgs(args)
            return .createTask(taskData)

        case "edit_task":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            let changes = try parseTaskChanges(args["changes"] as? [String: Any] ?? [:])
            return .editTask(taskQuery: query, changes: changes)

        case "delete_task":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            let deleteAll = args["delete_all_recurring"] as? Bool ?? false
            return .deleteTask(taskQuery: query, deleteAllRecurring: deleteAll)

        case "complete_task":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            return .completeTask(taskQuery: query)

        case "uncomplete_task":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            return .uncompleteTask(taskQuery: query)

        case "reschedule_task":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            let timeSpec = parseTimeSpec(args)
            return .rescheduleTask(taskQuery: query, newTime: timeSpec)

        case "move_to_inbox":
            let query = try parseTaskQuery(args["task_query"] as? [String: Any] ?? [:])
            return .moveToInbox(taskQuery: query)

        case "rearrange_schedule":
            let date = args["date"] as? String ?? "today"
            let strategyStr = args["strategy"] as? String ?? "optimize_gaps"
            let strategy = RearrangeStrategy(rawValue: strategyStr) ?? .optimizeGaps
            return .rearrangeSchedule(date: date, strategy: strategy)

        case "query_tasks":
            let filter = parseTaskFilter(args)
            return .queryTasks(filter: filter)

        case "query_prayers":
            let date = args["date"] as? String
            return .queryPrayers(date: date)

        case "find_available_slot":
            let duration = args["duration"] as? Int ?? 30
            let date = args["date"] as? String
            let preferredTime = args["preferred_time"] as? String
            let afterPrayer = args["after_prayer"] as? String
            let timeSpec = preferredTime != nil ? TimeSpec(time: preferredTime) : nil
            return .findAvailableSlot(duration: duration, date: date, preferredTime: timeSpec, afterPrayer: afterPrayer)

        case "toggle_nawafil":
            let nawafilType = args["nawafil_type"] as? String
            let enabled = args["enabled"] as? Bool ?? false
            return .toggleNawafil(type: nawafilType, enabled: enabled)

        case "ask_clarification":
            let request = try parseClarificationRequest(args)
            return .clarify(request)

        case "cannot_fulfill":
            let reason = args["reason"] as? String ?? "غير معروف"
            let alternative = args["alternative"] as? String
            let manualSteps = args["manual_steps"] as? [String]
            return .cannotFulfill(reason: reason, alternative: alternative, manualSteps: manualSteps)

        case "analyze_schedule":
            let date = args["date"] as? String
            let focusArea = args["focus_area"] as? String
            let suggestHabits = args["suggest_habits"] as? Bool ?? true
            let habitCategories = args["habit_categories"] as? [String]
            return .analyzeSchedule(date: date, focusArea: focusArea, suggestHabits: suggestHabits, habitCategories: habitCategories)

        default:
            MizanLogger.shared.lifecycle.error("Unknown tool call: \(result.functionName)")
            return .cannotFulfill(reason: "طلب غير معروف", alternative: nil, manualSteps: nil)
        }
    }

    // MARK: - Argument Parsing Helpers

    private func parseCreateTaskArgs(_ args: [String: Any]) throws -> ExtractedTaskData {
        let title = args["title"] as? String ?? ""
        let duration = args["duration"] as? Int ?? 30
        let categoryStr = args["category"] as? String
        var scheduledDate = args["scheduled_date"] as? String
        var scheduledTime = args["scheduled_time"] as? String
        let notes = args["notes"] as? String
        let addToInbox = args["add_to_inbox"] as? Bool ?? false
        let relativeMinutes = args["relative_minutes"] as? Int
        let timeOfDay = args["time_of_day"] as? String

        let calendar = Calendar.current
        let now = Date()

        // Handle relative_minutes - convert to actual scheduled time
        if let minutes = relativeMinutes, minutes >= 0 {
            let futureDate = now.addingTimeInterval(TimeInterval(minutes * 60))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            scheduledDate = dateFormatter.string(from: futureDate)

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            scheduledTime = timeFormatter.string(from: futureDate)
        }

        // Handle time_of_day - convert to scheduled_time if not already set
        if scheduledTime == nil, let tod = timeOfDay {
            switch tod {
            case "morning": scheduledTime = "09:00"
            case "mid_morning": scheduledTime = "10:00"
            case "noon": scheduledTime = "12:00"
            case "afternoon": scheduledTime = "14:00"
            case "evening": scheduledTime = "18:00"
            case "night": scheduledTime = "21:00"
            default: break
            }
            // Default to today if no date specified
            if scheduledDate == nil {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                scheduledDate = dateFormatter.string(from: now)
            }
        }

        // Handle special date values
        if let dateStr = scheduledDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            switch dateStr.lowercased() {
            case "today":
                scheduledDate = dateFormatter.string(from: now)
            case "tomorrow":
                if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                    scheduledDate = dateFormatter.string(from: tomorrow)
                }
            case "day_after_tomorrow":
                if let dayAfter = calendar.date(byAdding: .day, value: 2, to: now) {
                    scheduledDate = dateFormatter.string(from: dayAfter)
                }
            case "next_week":
                if let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) {
                    scheduledDate = dateFormatter.string(from: nextWeek)
                }
            case "saturday", "sunday", "monday", "tuesday", "wednesday", "thursday", "friday":
                scheduledDate = dateFormatter.string(from: nextWeekday(from: dateStr, after: now))
            default:
                break // Keep as-is (likely ISO8601 already)
            }
        }

        // Parse recurrence if present
        var recurrence: ExtractedTaskData.RecurrenceData? = nil
        if let recurrenceDict = args["recurrence"] as? [String: Any] {
            let frequencyStr = recurrenceDict["frequency"] as? String ?? "daily"
            let interval = recurrenceDict["interval"] as? Int ?? 1
            let daysOfWeek = recurrenceDict["days_of_week"] as? [Int]
            recurrence = ExtractedTaskData.RecurrenceData(
                frequency: frequencyStr,
                interval: interval,
                daysOfWeek: daysOfWeek
            )
        }

        return ExtractedTaskData(
            title: title,
            notes: notes,
            duration: duration,
            category: categoryStr,
            scheduledDate: addToInbox ? nil : scheduledDate,
            scheduledTime: addToInbox ? nil : scheduledTime,
            recurrence: recurrence,
            confidence: 1.0,
            clarificationNeeded: nil
        )
    }

    /// Helper to find the next occurrence of a weekday
    private func nextWeekday(from dayName: String, after date: Date) -> Date {
        let calendar = Calendar.current
        let weekdayMap: [String: Int] = [
            "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
            "thursday": 5, "friday": 6, "saturday": 7
        ]

        guard let targetWeekday = weekdayMap[dayName.lowercased()] else {
            return date
        }

        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7 // Next week
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date) ?? date
    }

    private func parseTaskQuery(_ args: [String: Any]) throws -> TaskQuery {
        return TaskQuery(
            titleContains: args["title_contains"] as? String,
            date: args["date"] as? String,
            category: args["category"] as? String,
            isCompleted: args["is_completed"] as? Bool,
            taskId: args["task_id"] as? String
        )
    }

    private func parseTaskChanges(_ args: [String: Any]) throws -> TaskChanges {
        return TaskChanges(
            title: args["title"] as? String,
            duration: args["duration"] as? Int,
            notes: args["notes"] as? String,
            category: args["category"] as? String,
            scheduledDate: args["scheduled_date"] as? String,
            scheduledTime: args["scheduled_time"] as? String
        )
    }

    private func parseTimeSpec(_ args: [String: Any]) -> TimeSpec {
        return TimeSpec(
            date: args["new_date"] as? String,
            time: args["new_time"] as? String,
            afterPrayer: args["after_prayer"] as? String,
            relativeMinutes: args["relative_minutes"] as? Int
        )
    }

    private func parseTaskFilter(_ args: [String: Any]) -> AITaskFilter {
        return AITaskFilter(
            date: args["date"] as? String,
            category: args["category"] as? String,
            isCompleted: args["is_completed"] as? Bool,
            inInbox: args["in_inbox"] as? Bool,
            isOverdue: args["is_overdue"] as? Bool,
            limit: args["limit"] as? Int
        )
    }

    private func parseClarificationRequest(_ args: [String: Any]) throws -> ClarificationRequest {
        let question = args["question"] as? String ?? "أحتاج توضيح"

        // Parse options if present
        var options: [ClarificationOption]? = nil
        if let optionsArray = args["options"] as? [[String: Any]] {
            options = optionsArray.map { optDict in
                ClarificationOption(
                    label: optDict["label"] as? String ?? "",
                    value: optDict["value"] as? String ?? "",
                    icon: optDict["icon"] as? String,
                    subtitle: optDict["subtitle"] as? String
                )
            }
        }

        // Parse partial data if present
        var partialData: PartialTaskData? = nil
        if let partialDict = args["partial_data"] as? [String: Any] {
            partialData = PartialTaskData(
                title: partialDict["title"] as? String,
                duration: partialDict["duration"] as? Int,
                category: partialDict["category"] as? String,
                scheduledDate: partialDict["scheduled_date"] as? String,
                scheduledTime: partialDict["scheduled_time"] as? String,
                notes: partialDict["notes"] as? String
            )
        }

        return ClarificationRequest(
            question: question,
            options: options,
            freeTextAllowed: true,
            partialData: partialData
        )
    }

    private func parseTaskFromResponse(_ response: String) throws -> ExtractedTaskData {
        // Clean up response - extract JSON if wrapped in markdown code blocks
        var jsonString = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw AIError.parsingFailed
        }

        do {
            let extracted = try JSONDecoder().decode(ExtractedTaskData.self, from: data)
            return extracted
        } catch {
            MizanLogger.shared.lifecycle.error("Failed to parse AI response: \(error.localizedDescription)")
            MizanLogger.shared.lifecycle.debug("Response was: \(jsonString)")
            throw AIError.parsingFailed
        }
    }
}

// MARK: - AI Errors

enum AIError: Error, LocalizedError {
    case noNetwork
    case apiKeyMissing
    case apiKeyInvalid
    case rateLimited(retryAfter: Int)
    case providerUnavailable(String)
    case invalidConfiguration
    case invalidResponse
    case emptyResponse
    case parsingFailed
    case httpError(statusCode: Int)
    case timeout

    var errorDescription: String? {
        switch self {
        case .noNetwork:
            return "No internet connection"
        case .apiKeyMissing:
            return "API key not configured"
        case .apiKeyInvalid:
            return "Invalid API key"
        case .rateLimited(let retryAfter):
            return "Rate limited. Try again in \(retryAfter) seconds"
        case .providerUnavailable(let provider):
            return "Provider \(provider) is not available"
        case .invalidConfiguration:
            return "Invalid AI configuration"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .emptyResponse:
            return "Empty response from AI service"
        case .parsingFailed:
            return "Failed to parse AI response"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .timeout:
            return "Request timed out"
        }
    }

    var localizedArabicDescription: String {
        switch self {
        case .noNetwork:
            return "لا يوجد اتصال بالإنترنت"
        case .apiKeyMissing:
            return "يرجى إضافة مفتاح API في الإعدادات"
        case .apiKeyInvalid:
            return "مفتاح API غير صالح"
        case .rateLimited(let retryAfter):
            return "حاول مرة أخرى بعد \(retryAfter) ثواني"
        case .providerUnavailable:
            return "الخدمة غير متوفرة حاليا"
        case .invalidConfiguration, .invalidResponse, .emptyResponse:
            return "حدث خطأ. حاول مرة أخرى"
        case .parsingFailed:
            return "لم أفهم. حاول مرة أخرى بصيغة أوضح"
        case .httpError:
            return "حدث خطأ في الاتصال"
        case .timeout:
            return "انتهت مهلة الاتصال"
        }
    }

    var recoveryAction: AIErrorRecoveryAction {
        switch self {
        case .noNetwork:
            return .useManualEntry
        case .apiKeyMissing, .apiKeyInvalid:
            return .configureAPIKey
        case .rateLimited:
            return .waitAndRetry
        case .providerUnavailable:
            return .switchProvider
        case .parsingFailed:
            return .retry
        case .invalidConfiguration, .invalidResponse, .emptyResponse, .httpError, .timeout:
            return .retry
        }
    }
}

enum AIErrorRecoveryAction {
    case retry
    case waitAndRetry
    case switchProvider
    case configureAPIKey
    case useManualEntry
}

// MARK: - AI Configuration Models

struct AIConfiguration: Codable {
    let version: String
    let defaultProvider: String
    let providers: [String: AIProviderConfig]
    let systemPrompt: AISystemPrompt
    let tools: [AITool]
    let taskExtraction: AITaskExtractionConfig
    let messages: AIMessages
    let quickSuggestions: AIQuickSuggestions
    let settings: AISettings
}

struct AIProviderConfig: Codable {
    let baseUrl: String
    let model: String
    let maxTokens: Int
    let temperature: Double
    let anthropicVersion: String?
}

struct AISystemPrompt: Codable {
    let arabic: String
    let english: String
}

struct AITool: Codable {
    let type: String
    let function: AIFunction

    struct AIFunction: Codable {
        let name: String
        let description: String
        let parameters: [String: Any]

        enum CodingKeys: String, CodingKey {
            case name, description, parameters
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)

            // Decode parameters as Any
            let parametersData = try container.decode(AnyCodable.self, forKey: .parameters)
            parameters = parametersData.value as? [String: Any] ?? [:]
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(description, forKey: .description)
            try container.encode(AnyCodable(parameters), forKey: .parameters)
        }
    }
}

struct AITaskExtractionConfig: Codable {
    let systemPromptArabic: String
    let systemPromptEnglish: String
}

struct AIMessages: Codable {
    let welcomeArabic: String
    let welcomeEnglish: String
    let errorNoNetworkArabic: String
    let errorNoNetworkEnglish: String
    let errorApiKeyArabic: String
    let errorApiKeyEnglish: String
    let errorRateLimitArabic: String
    let errorRateLimitEnglish: String
    let errorParsingArabic: String
    let errorParsingEnglish: String
    let confirmationArabic: String
    let confirmationEnglish: String
    let taskCreatedArabic: String?
    let taskCreatedEnglish: String?
    let taskDeletedArabic: String?
    let taskDeletedEnglish: String?
    let taskEditedArabic: String?
    let taskEditedEnglish: String?
    let taskCompletedArabic: String?
    let taskCompletedEnglish: String?
    let clarificationNeededArabic: String?
    let clarificationNeededEnglish: String?
}

struct AIQuickSuggestions: Codable {
    let arabic: [String]
    let english: [String]
}

struct AISettings: Codable {
    let maxMessagesInHistory: Int
    let requestTimeoutSeconds: Int
    let maxRetries: Int
    let retryDelaySeconds: [Int]
    let toolCallEnabled: Bool?
}

// MARK: - Tool Call Response Models

/// Result from a tool call
struct ToolCallResult {
    let functionName: String
    let arguments: String
    let textContent: String?
}

/// OpenAI response with tool calls
struct OpenAIToolResponse: Codable {
    let choices: [OpenAIToolChoice]

    struct OpenAIToolChoice: Codable {
        let message: OpenAIToolMessage
        let finishReason: String?

        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }

    struct OpenAIToolMessage: Codable {
        let role: String
        let content: String?
        let toolCalls: [OpenAIToolCall]?

        enum CodingKeys: String, CodingKey {
            case role, content
            case toolCalls = "tool_calls"
        }
    }

    struct OpenAIToolCall: Codable {
        let id: String
        let type: String
        let function: OpenAIFunctionCall
    }

    struct OpenAIFunctionCall: Codable {
        let name: String
        let arguments: String
    }
}

/// Claude response with tool use
struct ClaudeToolResponse: Codable {
    let content: [ClaudeContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }

    struct ClaudeContentBlock: Codable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
        let input: [String: Any]?

        enum CodingKeys: String, CodingKey {
            case type, text, id, name, input
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decode(String.self, forKey: .type)
            text = try container.decodeIfPresent(String.self, forKey: .text)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)

            // Decode input as Any if present
            if container.contains(.input) {
                let inputData = try container.decode(AnyCodable.self, forKey: .input)
                input = inputData.value as? [String: Any]
            } else {
                input = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(id, forKey: .id)
            try container.encodeIfPresent(name, forKey: .name)
            if let input = input {
                try container.encode(AnyCodable(input), forKey: .input)
            }
        }
    }
}

// MARK: - AnyCodable Helper

/// Helper struct to decode/encode Any values from JSON
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unable to encode value"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
