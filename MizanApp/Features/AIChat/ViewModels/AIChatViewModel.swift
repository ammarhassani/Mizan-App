//
//  AIChatViewModel.swift
//  Mizan
//
//  ViewModel for AI Chat feature - manages chat state, intent execution, and action results
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

    // MARK: - V2 Agent Properties

    /// Current action result to display (replaces text-only responses)
    @Published var currentActionResult: AIActionResult?

    /// Current clarification request (if AI needs more info)
    @Published var currentClarification: ClarificationRequest?

    /// Pending action awaiting confirmation
    @Published var pendingAction: PendingAction?

    /// Task disambiguation (when multiple tasks match)
    @Published var disambiguationTasks: [TaskSummary]?
    @Published var disambiguationQuestion: String?

    /// Whether to use V2 agent mode (full app management)
    @Published var useAgentMode: Bool = true

    // MARK: - All-in-One Task Creation Card

    /// Pending task data for the all-in-one creation card
    @Published var pendingTaskData: ExtractedTaskData?

    /// Whether to show the all-in-one task creation card
    @Published var showTaskCreationCard: Bool = false

    // MARK: - Dependencies

    private let aiService: AITaskService
    private let modelContext: ModelContext
    private let userSettings: UserSettings
    private let prayerTimeService: PrayerTimeService
    private var actionExecutor: AIActionExecutor?
    private var contextBuilder: AIContextBuilder?

    // MARK: - Configuration

    private let config: AIConfiguration

    // MARK: - Callbacks

    /// Called when an action navigates to a different screen
    var onNavigate: ((ManualAction) -> Void)?

    /// Called when task is created (for timeline refresh)
    var onTaskCreated: ((Task) -> Void)?

    /// Called when task is modified (for timeline refresh)
    var onTaskModified: (() -> Void)?

    // MARK: - Initialization

    init(
        aiService: AITaskService,
        modelContext: ModelContext,
        userSettings: UserSettings,
        prayerTimeService: PrayerTimeService? = nil
    ) {
        self.aiService = aiService
        self.modelContext = modelContext
        self.userSettings = userSettings
        self.prayerTimeService = prayerTimeService ?? PrayerTimeService(
            networkClient: NetworkClient(),
            cacheManager: CacheManager(),
            modelContext: modelContext
        )
        self.config = ConfigurationManager.shared.aiConfig

        // Initialize V2 components
        setupV2Components()

        // Add welcome message
        addWelcomeMessage()
    }

    private func setupV2Components() {
        contextBuilder = AIContextBuilder(
            modelContext: modelContext,
            prayerTimeService: prayerTimeService,
            userSettings: userSettings
        )

        actionExecutor = AIActionExecutor(
            modelContext: modelContext,
            userSettings: userSettings,
            prayerTimeService: prayerTimeService
        )
    }

    // MARK: - Public Methods

    /// Send a message and get AI response
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Clear input immediately
        inputText = ""

        // Clear previous results
        currentActionResult = nil
        currentClarification = nil
        disambiguationTasks = nil
        disambiguationQuestion = nil

        // Add user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Start processing
        isProcessing = true
        error = nil

        // Use V2 agent mode or V1 extraction mode
        if useAgentMode {
            await processMessageV2(text)
        } else {
            await processMessageV1(text)
        }

        isProcessing = false
    }

    // MARK: - V2 Agent Processing

    /// Process message using V2 agent with full intent system
    private func processMessageV2(_ text: String) async {
        guard let contextBuilder = contextBuilder, let actionExecutor = actionExecutor else {
            await processMessageV1(text) // Fallback to V1
            return
        }

        do {
            // Build context
            let context = try await contextBuilder.buildContext()

            // Process message to get intent
            let intent = try await aiService.processMessage(
                text,
                context: context,
                conversationHistory: Array(messages.dropLast())
            )

            // Handle the intent
            await handleIntent(intent, using: actionExecutor)

        } catch let aiError as AIError {
            handleAIError(aiError)
        } catch {
            print("[AIChatViewModel] V2 processing failed: \(error.localizedDescription)")
            // Fallback to V1
            await processMessageV1(text)
        }
    }

    /// Handle the parsed intent
    private func handleIntent(_ intent: AIIntent, using executor: AIActionExecutor) async {
        switch intent {
        case .clarify(let request):
            // AI needs more information
            currentClarification = request
            addAssistantMessage("🤔 \(request.question)")
            HapticManager.shared.trigger(.warning)

        case .createTask(let data):
            // Check if required fields are missing
            let isMissingTime = data.scheduledDate == nil && data.scheduledTime == nil
            let isDefaultDuration = data.duration == 30

            if isMissingTime || isDefaultDuration {
                // Show all-in-one task creation card to collect missing fields
                pendingTaskData = data
                showTaskCreationCard = true
                addAssistantMessage("📝 أكمل تفاصيل المهمة: \(data.title)")
                HapticManager.shared.trigger(.light)
            } else {
                // All fields provided, show preview for user confirmation
                extractedTask = data
                showTaskReview = true
                let responseMessage = buildResponseMessage(for: data)
                messages.append(responseMessage)
                HapticManager.shared.trigger(.success)
            }

        case .deleteTask, .editTask, .completeTask, .uncompleteTask, .rescheduleTask, .rearrangeSchedule:
            // Execute with confirmation
            let result = await executor.executeWithErrorHandling(intent)
            handleActionResult(result)

        case .queryTasks, .queryPrayers, .querySchedule, .queryAvailableTime:
            // Execute read-only queries immediately
            let result = await executor.executeWithErrorHandling(intent)
            handleActionResult(result)

        case .toggleNawafil, .changeSetting:
            // Execute settings changes
            let result = await executor.executeWithErrorHandling(intent)
            handleActionResult(result)

        case .moveToInbox(let query):
            let result = await executor.executeWithErrorHandling(.moveToInbox(taskQuery: query))
            handleActionResult(result)

        case .findAvailableSlot(let duration, let date, let preferredTime, let afterPrayer):
            let result = await executor.executeWithErrorHandling(.findAvailableSlot(duration: duration, date: date, preferredTime: preferredTime, afterPrayer: afterPrayer))
            handleActionResult(result)

        case .suggest(let suggestions):
            currentActionResult = .suggestions(suggestions)
            addAssistantMessage("💡 اقتراحات:")
            HapticManager.shared.trigger(.light)

        case .explain(let topic):
            currentActionResult = .explanation(topic)
            addAssistantMessage(topic)
            HapticManager.shared.trigger(.light)

        case .cannotFulfill(let reason, let alternative, _):
            currentActionResult = .cannotFulfill(reason: reason, alternative: alternative, manualAction: nil)
            addAssistantMessage("⚠️ \(reason)")
            if let alt = alternative {
                addAssistantMessage("💡 \(alt)")
            }
            HapticManager.shared.trigger(.warning)
        }
    }

    /// Handle the action result from executor
    private func handleActionResult(_ result: AIActionResult) {
        currentActionResult = result

        switch result {
        case .taskCreated(let task, _):
            addAssistantMessage("✅ تم إنشاء المهمة: \(task.title)")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskEdited(let task, let changes):
            let changesText = changes.joined(separator: "، ")
            addAssistantMessage("✏️ تم تعديل \(task.title): \(changesText)")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskDeleted(let title, _):
            addAssistantMessage("🗑️ تم حذف: \(title)")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskCompleted(let task):
            addAssistantMessage("✅ تم إكمال: \(task.title)")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskUncompleted(let task):
            addAssistantMessage("↩️ تم إلغاء إكمال: \(task.title)")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskAlreadyCompleted(let title):
            addAssistantMessage("ℹ️ المهمة \"\(title)\" مكتملة بالفعل")
            HapticManager.shared.trigger(.light)

        case .taskRescheduled(let task, _, let newTime):
            addAssistantMessage("📅 تم نقل \(task.title) إلى \(newTime ?? "وقت جديد")")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .taskMovedToInbox(let task):
            addAssistantMessage("📥 تم نقل \(task.title) إلى صندوق الوارد")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .scheduleRearranged(let count, _):
            addAssistantMessage("📊 تم إعادة ترتيب \(count) مهام")
            onTaskModified?()
            HapticManager.shared.trigger(.success)

        case .slotFound(let slot):
            addAssistantMessage("⏰ وقت متاح: \(slot.formattedRange) (\(slot.durationMinutes) دقيقة)")
            HapticManager.shared.trigger(.light)

        case .taskList(let tasks):
            if tasks.isEmpty {
                addAssistantMessage("📋 لا توجد مهام")
            } else {
                addAssistantMessage("📋 \(tasks.count) مهام:")
            }
            HapticManager.shared.trigger(.light)

        case .prayerList:
            addAssistantMessage("🕌 أوقات الصلاة:")
            HapticManager.shared.trigger(.light)

        case .schedule(let tasks, let prayers):
            addAssistantMessage("📅 الجدول: \(tasks.count) مهام، \(prayers.count) صلوات")
            HapticManager.shared.trigger(.light)

        case .availableSlots(let slots):
            if slots.isEmpty {
                addAssistantMessage("⏰ لا توجد أوقات متاحة")
            } else {
                addAssistantMessage("⏰ \(slots.count) أوقات متاحة:")
            }
            HapticManager.shared.trigger(.light)

        case .nawafilToggled(let type, let enabled):
            let status = enabled ? "تفعيل" : "تعطيل"
            let typeName = type ?? "جميع النوافل"
            addAssistantMessage("✨ تم \(status) \(typeName)")
            HapticManager.shared.trigger(.success)

        case .settingChanged(let key, _, let newValue):
            addAssistantMessage("⚙️ تم تغيير \(key) إلى \(newValue)")
            HapticManager.shared.trigger(.success)

        case .needsClarification(let request):
            currentClarification = request
            addAssistantMessage("🤔 \(request.question)")
            HapticManager.shared.trigger(.warning)

        case .prayerConflict(let prayerName, let suggestedTime, _):
            addAssistantMessage("⚠️ هذا الوقت قريب من صلاة \(prayerName). الوقت المقترح: \(suggestedTime)")
            HapticManager.shared.trigger(.warning)

        case .cannotFulfill(let reason, let alternative, _):
            addAssistantMessage("❌ \(reason)")
            if let alt = alternative {
                addAssistantMessage("💡 \(alt)")
            }
            HapticManager.shared.trigger(.error)

        case .confirmationRequired(let action):
            pendingAction = action
            addAssistantMessage("⚠️ \(action.description)")
            HapticManager.shared.trigger(.warning)

        case .suggestions(let suggestions):
            addAssistantMessage("💡 اقتراحات:\n" + suggestions.map { "• \($0)" }.joined(separator: "\n"))
            HapticManager.shared.trigger(.light)

        case .explanation(let text):
            addAssistantMessage(text)
            HapticManager.shared.trigger(.light)
        }

        // Auto-dismiss successful results after delay
        if result.shouldAutoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + result.autoDismissDelay) { [weak self] in
                if self?.currentActionResult?.title == result.title {
                    self?.currentActionResult = nil
                }
            }
        }
    }

    // MARK: - V1 Processing (Fallback)

    /// Process message using V1 task extraction (fallback)
    private func processMessageV1(_ text: String) async {
        do {
            // Extract task from message
            let extracted = try await aiService.extractTask(
                from: text,
                conversationHistory: Array(messages.dropLast())
            )

            // Add assistant response with extracted task
            let responseMessage = buildResponseMessage(for: extracted)
            messages.append(responseMessage)

            // Store extracted task for review
            extractedTask = extracted
            showTaskReview = true

            HapticManager.shared.trigger(.success)

        } catch let aiError as AIError {
            handleAIError(aiError)
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
    }

    private func handleAIError(_ aiError: AIError) {
        self.error = aiError
        self.showError = true

        let errorMessage = ChatMessage(
            role: .assistant,
            content: aiError.localizedArabicDescription
        )
        messages.append(errorMessage)

        HapticManager.shared.trigger(.error)
    }

    private func addAssistantMessage(_ content: String) {
        let message = ChatMessage(role: .assistant, content: content)
        messages.append(message)
    }

    // MARK: - Clarification Handling

    /// Handle user selecting a clarification option
    func handleClarificationOption(_ option: ClarificationOption) async {
        // Add user's choice as a message
        let userMessage = ChatMessage(role: .user, content: option.label)
        messages.append(userMessage)

        // Clear clarification state
        currentClarification = nil

        // Process the response
        isProcessing = true
        await processMessageV2(option.value)
        isProcessing = false
    }

    /// Handle free text response to clarification
    func handleClarificationFreeText(_ text: String) async {
        guard !text.isEmpty else { return }

        // Add user's text as a message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Clear clarification state
        currentClarification = nil

        // Process the response
        isProcessing = true
        await processMessageV2(text)
        isProcessing = false
    }

    // MARK: - Confirmation Handling

    /// Confirm pending action
    func confirmPendingAction() {
        guard let action = pendingAction else { return }

        // Execute the callback
        action.confirmCallback?()

        // Clear pending action and result card
        pendingAction = nil
        currentActionResult = nil

        // Add confirmation message
        addAssistantMessage("✅ تم تنفيذ الإجراء")
        HapticManager.shared.trigger(.success)

        // Notify about modification
        onTaskModified?()
    }

    /// Cancel pending action
    func cancelPendingAction() {
        pendingAction = nil
        currentActionResult = nil
        addAssistantMessage("↩️ تم إلغاء الإجراء")
        HapticManager.shared.trigger(.light)
    }

    // MARK: - Disambiguation Handling

    /// Handle user selecting a task from disambiguation
    func handleTaskDisambiguation(_ task: TaskSummary) async {
        // Clear disambiguation state
        disambiguationTasks = nil
        disambiguationQuestion = nil

        // Add user's choice
        let userMessage = ChatMessage(role: .user, content: task.title)
        messages.append(userMessage)

        // Re-process with specific task ID
        inputText = "المهمة: \(task.id)"
        await sendMessage()
    }

    // MARK: - Manual Navigation

    /// Handle manual action navigation
    func handleManualAction(_ action: ManualAction) {
        onNavigate?(action)
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

    // MARK: - All-in-One Task Creation Card

    /// Complete task creation from the all-in-one card
    func completeTaskCreation(scheduledDate: Date, duration: Int, recurrence: RecurrenceOption) {
        guard var data = pendingTaskData else { return }

        // Update the extracted data with user selections
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        data.scheduledDate = dateFormatter.string(from: scheduledDate)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        data.scheduledTime = timeFormatter.string(from: scheduledDate)

        data.duration = duration

        // Handle recurrence
        if recurrence != .oneTime {
            data.recurrence = ExtractedTaskData.RecurrenceData(
                frequency: recurrence.rawValue,
                interval: 1,
                daysOfWeek: nil
            )
        }

        // Create the task
        let task = data.toTask()
        modelContext.insert(task)

        do {
            try modelContext.save()
            MizanLogger.shared.task.info("Task created from AI card: \(task.title)")

            // Add confirmation message
            let confirmMessage = ChatMessage(
                role: .assistant,
                content: "✅ تم إضافة المهمة: \(task.title)"
            )
            messages.append(confirmMessage)

            // Reset state
            pendingTaskData = nil
            showTaskCreationCard = false

            // Notify listeners
            onTaskCreated?(task)
            onTaskModified?()

            HapticManager.shared.trigger(.success)
        } catch {
            MizanLogger.shared.task.error("Failed to save task from card: \(error.localizedDescription)")

            let errorMessage = ChatMessage(
                role: .assistant,
                content: "حدث خطأ أثناء حفظ المهمة. حاول مرة أخرى."
            )
            messages.append(errorMessage)

            HapticManager.shared.trigger(.error)
        }
    }

    /// Cancel the all-in-one task creation card
    func cancelTaskCreation() {
        pendingTaskData = nil
        showTaskCreationCard = false

        let cancelMessage = ChatMessage(
            role: .assistant,
            content: "تم الإلغاء. أخبرني بمهمة أخرى."
        )
        messages.append(cancelMessage)
        HapticManager.shared.trigger(.light)
    }

    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        extractedTask = nil
        showTaskReview = false
        currentActionResult = nil
        currentClarification = nil
        disambiguationTasks = nil
        disambiguationQuestion = nil
        pendingTaskData = nil
        showTaskCreationCard = false
        pendingAction = nil
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
