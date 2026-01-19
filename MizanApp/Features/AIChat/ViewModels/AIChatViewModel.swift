//
//  AIChatViewModel.swift
//  Mizan
//
//  ViewModel for AI Chat feature - manages chat state and task extraction
//

import SwiftUI
import SwiftData
import Combine
import os.log

@MainActor
final class AIChatViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var extractedTask: ExtractedTaskData?
    @Published var showTaskReview: Bool = false
    @Published var error: AIError?
    @Published var showError: Bool = false

    // MARK: - Dependencies

    private let aiService: AITaskService
    private let modelContext: ModelContext
    private let userSettings: UserSettings

    // MARK: - Configuration

    private let config: AIConfiguration

    // MARK: - Initialization

    init(aiService: AITaskService, modelContext: ModelContext, userSettings: UserSettings) {
        self.aiService = aiService
        self.modelContext = modelContext
        self.userSettings = userSettings
        self.config = ConfigurationManager.shared.aiConfig

        // Add welcome message
        addWelcomeMessage()
    }

    // MARK: - Public Methods

    /// Send a message and get AI response
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Clear input immediately
        inputText = ""

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Start processing
        isProcessing = true
        error = nil

        do {
            // Extract task from message
            let extracted = try await aiService.extractTask(
                from: text,
                conversationHistory: Array(messages.dropLast()) // Exclude current message
            )

            // Add assistant response with extracted task
            let responseMessage = buildResponseMessage(for: extracted)
            messages.append(responseMessage)

            // Store extracted task for review
            extractedTask = extracted
            showTaskReview = true

            HapticManager.shared.trigger(.success)

        } catch let aiError as AIError {
            self.error = aiError
            self.showError = true

            // Add error message to chat
            let errorMessage = ChatMessage(
                role: .assistant,
                content: aiError.localizedArabicDescription
            )
            messages.append(errorMessage)

            HapticManager.shared.trigger(.error)
        } catch {
            self.error = .parsingFailed
            self.showError = true

            let errorMessage = ChatMessage(
                role: .assistant,
                content: config.messages.errorParsingArabic
            )
            messages.append(errorMessage)

            HapticManager.shared.trigger(.error)
        }

        isProcessing = false
    }

    /// Confirm and create the extracted task
    func confirmTask() -> Task? {
        guard let extracted = extractedTask else { return nil }

        let task = extracted.toTask()
        modelContext.insert(task)

        do {
            try modelContext.save()
            MizanLogger.shared.task.info("Task created from AI: \(task.title)")

            // Add confirmation message
            let confirmMessage = ChatMessage(
                role: .assistant,
                content: "تم إضافة المهمة: \(task.title)"
            )
            messages.append(confirmMessage)

            // Reset state
            extractedTask = nil
            showTaskReview = false

            HapticManager.shared.trigger(.success)

            return task
        } catch {
            MizanLogger.shared.task.error("Failed to save AI-created task: \(error.localizedDescription)")

            let errorMessage = ChatMessage(
                role: .assistant,
                content: "حدث خطأ أثناء حفظ المهمة. حاول مرة أخرى."
            )
            messages.append(errorMessage)

            HapticManager.shared.trigger(.error)

            return nil
        }
    }

    /// Edit a field in the extracted task
    func updateExtractedTask(title: String? = nil, duration: Int? = nil, notes: String? = nil) {
        guard var task = extractedTask else { return }

        if let title = title {
            task.title = title
        }
        if let duration = duration {
            task.duration = duration
        }
        if let notes = notes {
            task.notes = notes
        }

        extractedTask = task
    }

    /// Cancel the current extraction
    func cancelExtraction() {
        extractedTask = nil
        showTaskReview = false

        let cancelMessage = ChatMessage(
            role: .assistant,
            content: "تم الإلغاء. أخبرني بمهمة أخرى."
        )
        messages.append(cancelMessage)
    }

    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        extractedTask = nil
        showTaskReview = false
        addWelcomeMessage()
    }

    /// Use a quick suggestion
    func useQuickSuggestion(_ suggestion: String) {
        inputText = suggestion
    }

    /// Get quick suggestions based on language
    var quickSuggestions: [String] {
        // Use Arabic suggestions (primary language)
        return config.quickSuggestions.arabic
    }

    /// Check if AI service is available
    var isServiceAvailable: Bool {
        aiService.isAvailable
    }

    /// Check if API key is configured
    var hasAPIKey: Bool {
        aiService.getAPIKey(for: aiService.currentProvider) != nil
    }

    /// Set API key for current provider
    func setAPIKey(_ key: String) {
        aiService.setAPIKey(key, for: aiService.currentProvider)
    }

    // MARK: - Private Methods

    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            role: .assistant,
            content: config.messages.welcomeArabic
        )
        messages.append(welcomeMessage)
    }

    private func buildResponseMessage(for extracted: ExtractedTaskData) -> ChatMessage {
        var content = config.messages.confirmationArabic + "\n\n"

        // Build task summary
        content += "📝 \(extracted.title)\n"

        if let date = extracted.scheduledDate {
            content += "📅 \(date)"
            if let time = extracted.scheduledTime {
                content += " - \(time)"
            }
            content += "\n"
        }

        content += "⏱ \(extracted.duration) دقيقة\n"

        if let category = extracted.category {
            let categoryName = getCategoryArabicName(category)
            content += "📁 \(categoryName)\n"
        }

        if let recurrence = extracted.recurrence {
            let recurrenceText = getRecurrenceArabicText(recurrence)
            content += "🔄 \(recurrenceText)\n"
        }

        if let clarification = extracted.clarificationNeeded {
            content += "\n⚠️ \(clarification)"
        }

        return ChatMessage(
            role: .assistant,
            content: content,
            extractedTask: extracted
        )
    }

    private func getCategoryArabicName(_ category: String) -> String {
        switch category.lowercased() {
        case "work": return "عمل"
        case "personal": return "شخصي"
        case "study": return "دراسة"
        case "health": return "صحة"
        case "social": return "اجتماعي"
        case "worship": return "عبادة"
        default: return category
        }
    }

    private func getRecurrenceArabicText(_ recurrence: ExtractedTaskData.RecurrenceData) -> String {
        switch recurrence.frequency.lowercased() {
        case "daily":
            return recurrence.interval == 1 ? "يوميا" : "كل \(recurrence.interval) أيام"
        case "weekly":
            return recurrence.interval == 1 ? "أسبوعيا" : "كل \(recurrence.interval) أسابيع"
        case "monthly":
            return recurrence.interval == 1 ? "شهريا" : "كل \(recurrence.interval) أشهر"
        default:
            return recurrence.frequency
        }
    }
}
