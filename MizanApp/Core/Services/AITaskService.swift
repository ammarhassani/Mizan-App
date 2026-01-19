//
//  AITaskService.swift
//  Mizan
//
//  AI-powered task extraction service with multi-provider support
//

import Foundation
import Network
import os.log

// MARK: - AI Task Service Protocol

protocol AITaskServiceProtocol {
    func extractTask(from message: String, conversationHistory: [ChatMessage]) async throws -> ExtractedTaskData
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

    // MARK: - Task Extraction

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
        let systemPrompt = buildSystemPrompt()
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

    // MARK: - Private Methods

    private func buildSystemPrompt() -> String {
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
}
