//
//  AIChatSheet.swift
//  Mizan
//
//  AI-powered chat interface for natural language task creation and app management
//

import SwiftUI
import SwiftData

struct AIChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @StateObject private var viewModel: AIChatViewModel

    @FocusState private var isInputFocused: Bool

    // Callbacks
    var onTaskCreated: ((Task) -> Void)?
    var onTaskModified: (() -> Void)?
    var onNavigate: ((ManualAction) -> Void)?

    init(
        onTaskCreated: ((Task) -> Void)? = nil,
        onTaskModified: (() -> Void)? = nil,
        onNavigate: ((ManualAction) -> Void)? = nil
    ) {
        self.onTaskCreated = onTaskCreated
        self.onTaskModified = onTaskModified
        self.onNavigate = onNavigate

        // ViewModel will be initialized with dependencies
        _viewModel = StateObject(wrappedValue: AIChatViewModel(
            aiService: AppEnvironment.shared.aiTaskService,
            modelContext: AppEnvironment.shared.modelContainer.mainContext,
            userSettings: AppEnvironment.shared.userSettings,
            prayerTimeService: AppEnvironment.shared.prayerTimeService
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat messages - takes all available space
                    chatMessagesView

                    // Bottom section - cards and input anchored to bottom
                    VStack(spacing: 0) {
                        // V2: Action result card (when available)
                        if let result = viewModel.currentActionResult {
                            actionResultSection(result)
                        }

                        // V2: Clarification card - DISABLED (per user request)
                        // if let clarification = viewModel.currentClarification {
                        //     clarificationSection(clarification)
                        // }

                        // V2: Task disambiguation card (when multiple tasks match)
                        if let tasks = viewModel.disambiguationTasks,
                           let question = viewModel.disambiguationQuestion {
                            disambiguationSection(question: question, tasks: tasks)
                        }

                        // All-in-one task creation card (when AI detected task with missing fields)
                        if viewModel.showTaskCreationCard, let taskData = viewModel.pendingTaskData {
                            taskCreationSection(taskData)
                        }

                        // Task preview card (when task is extracted - V1 compatible)
                        if viewModel.showTaskReview, let task = viewModel.extractedTask {
                            taskPreviewCard(task)
                        }

                        // Input bar
                        inputBarView
                    }
                }
            }
            .navigationTitle("مساعد المهام")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إغلاق") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Toggle agent mode
                        Button {
                            viewModel.useAgentMode.toggle()
                        } label: {
                            Label(
                                viewModel.useAgentMode ? "وضع بسيط" : "وضع ذكي",
                                systemImage: viewModel.useAgentMode ? "brain" : "sparkle"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("مسح المحادثة", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
            .onAppear {
                // Set up callbacks
                viewModel.onTaskCreated = onTaskCreated
                viewModel.onTaskModified = onTaskModified
                viewModel.onNavigate = { action in
                    onNavigate?(action)
                    dismiss()
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled(viewModel.isProcessing)
    }

    // MARK: - Computed Properties

    /// Whether to show the welcome screen (empty state)
    private var shouldShowWelcome: Bool {
        viewModel.messages.isEmpty &&
        !viewModel.isProcessing &&
        !viewModel.showTaskReview &&
        !viewModel.showTaskCreationCard &&
        viewModel.currentClarification == nil &&
        viewModel.currentActionResult == nil &&
        viewModel.disambiguationTasks == nil
    }

    /// Whether to show inline quick suggestions (legacy, now in welcome view)
    private var shouldShowQuickSuggestions: Bool {
        // Quick suggestions are now in the welcome view
        false
    }

    // MARK: - Chat Messages

    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if shouldShowWelcome {
                    // Welcome screen
                    AIWelcomeView(
                        suggestions: viewModel.quickSuggestions,
                        onSuggestionTap: { suggestion in
                            viewModel.useQuickSuggestion(suggestion)
                            isInputFocused = true
                        }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    // Chat messages
                    LazyVStack(spacing: MZSpacing.md) {
                        ForEach(viewModel.messages) { message in
                            messageView(for: message)
                                .id(message.id)
                        }

                        // Modern typing indicator
                        if viewModel.isProcessing {
                            ModernTypingIndicator()
                                .id("typing")
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(MZSpacing.md)
                }
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to bottom on new message
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessing) { _, isProcessing in
                if isProcessing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Message View Factory

    @ViewBuilder
    private func messageView(for message: ChatMessage) -> some View {
        if message.role == .user {
            UserMessageView(
                message: message,
                showTimestamp: shouldShowTimestamp(for: message)
            )
        } else {
            AIMessageView(
                message: message,
                showTimestamp: shouldShowTimestamp(for: message)
            )
        }
    }

    /// Determine if timestamp should be shown (show for last message or if gap > 5 min)
    private func shouldShowTimestamp(for message: ChatMessage) -> Bool {
        guard let index = viewModel.messages.firstIndex(where: { $0.id == message.id }) else {
            return true
        }

        // Always show for last message
        if index == viewModel.messages.count - 1 {
            return true
        }

        // Show if next message is more than 5 minutes later
        let nextIndex = index + 1
        if nextIndex < viewModel.messages.count {
            let nextMessage = viewModel.messages[nextIndex]
            let gap = nextMessage.timestamp.timeIntervalSince(message.timestamp)
            return gap > 300 // 5 minutes
        }

        return false
    }

    // MARK: - Quick Suggestions (Legacy - now in welcome view)

    private var quickSuggestionsView: some View {
        EmptyView()
    }

    // MARK: - V2 Action Result Section

    private func actionResultSection(_ result: AIActionResult) -> some View {
        AIActionCard(
            result: result,
            onConfirm: {
                viewModel.confirmPendingAction()
            },
            onCancel: {
                viewModel.cancelPendingAction()
            },
            onManualAction: { action in
                viewModel.handleManualAction(action)
            }
        )
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentActionResult != nil)
    }

    // MARK: - V2 Clarification Section

    private func clarificationSection(_ clarification: ClarificationRequest) -> some View {
        AIClarificationCard(
            request: clarification,
            onOptionSelected: { option in
                _Concurrency.Task {
                    await viewModel.handleClarificationOption(option)
                }
            },
            onFreeTextSubmit: { text in
                _Concurrency.Task {
                    await viewModel.handleClarificationFreeText(text)
                }
            }
        )
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentClarification != nil)
    }

    // MARK: - V2 Task Disambiguation Section

    private func disambiguationSection(question: String, tasks: [TaskSummary]) -> some View {
        AITaskDisambiguationCard(
            question: question,
            tasks: tasks,
            onTaskSelected: { task in
                _Concurrency.Task {
                    await viewModel.handleTaskDisambiguation(task)
                }
            }
        )
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.disambiguationTasks != nil)
    }

    // MARK: - All-in-One Task Creation Section

    private func taskCreationSection(_ taskData: ExtractedTaskData) -> some View {
        AITaskCreationCard(
            taskTitle: taskData.title,
            category: taskData.category,
            onComplete: { scheduledDate, duration, recurrence in
                viewModel.completeTaskCreation(
                    scheduledDate: scheduledDate,
                    duration: duration,
                    recurrence: recurrence
                )
            },
            onCancel: {
                viewModel.cancelTaskCreation()
            }
        )
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: viewModel.showTaskCreationCard)
    }

    // MARK: - Task Preview Card

    private func taskPreviewCard(_ task: ExtractedTaskData) -> some View {
        VStack(spacing: MZSpacing.sm) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.successColor)
                Text("معاينة المهمة")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }

            // Task details
            VStack(alignment: .leading, spacing: MZSpacing.xs) {
                HStack {
                    Image(systemName: TaskIconDetector.shared.detectIcon(from: task.title))
                        .foregroundColor(themeManager.primaryColor)
                    Text(task.title)
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                HStack(spacing: MZSpacing.md) {
                    if let date = task.scheduledDate {
                        Label(date, systemImage: "calendar")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    if let time = task.scheduledTime {
                        Label(time, systemImage: "clock")
                            .font(MZTypography.labelSmall)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    Label("\(task.duration) د", systemImage: "timer")
                        .font(MZTypography.labelSmall)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            // Action buttons
            HStack(spacing: MZSpacing.sm) {
                Button {
                    viewModel.cancelExtraction()
                } label: {
                    Text("إلغاء")
                        .font(MZTypography.labelMedium)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MZSpacing.sm)
                        .background(themeManager.surfaceSecondaryColor)
                        .cornerRadius(themeManager.cornerRadius(.medium))
                }

                Button {
                    if let createdTask = viewModel.confirmTask() {
                        onTaskCreated?(createdTask)
                        HapticManager.shared.trigger(.success)
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("إضافة")
                    }
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.sm)
                    .background(themeManager.primaryColor)
                    .cornerRadius(themeManager.cornerRadius(.medium))
                }
            }
        }
        .padding(MZSpacing.md)
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
        .shadow(color: themeManager.textPrimaryColor.opacity(0.1), radius: 8, y: 4)
        .padding(MZSpacing.md)
    }

    // MARK: - Input Bar

    private var inputBarView: some View {
        SimpleChatInputBar(
            text: $viewModel.inputText,
            isProcessing: viewModel.isProcessing,
            placeholder: "اكتب رسالتك...",
            onSend: sendMessage,
            isFocused: $isInputFocused
        )
    }

    // MARK: - Actions

    private func sendMessage() {
        guard !viewModel.inputText.isEmpty && !viewModel.isProcessing else { return }

        isInputFocused = false
        HapticManager.shared.trigger(.light)

        _Concurrency.Task {
            await viewModel.sendMessage()
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatSheet()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
