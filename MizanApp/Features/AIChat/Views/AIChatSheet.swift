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

                        // V2: Clarification card (when AI needs more info)
                        if let clarification = viewModel.currentClarification {
                            clarificationSection(clarification)
                        }

                        // V2: Task disambiguation card (when multiple tasks match)
                        if let tasks = viewModel.disambiguationTasks,
                           let question = viewModel.disambiguationQuestion {
                            disambiguationSection(question: question, tasks: tasks)
                        }

                        // All-in-one task creation card (when AI detected task with missing fields)
                        if viewModel.showTaskCreationCard, let taskData = viewModel.pendingTaskData {
                            taskCreationSection(taskData)
                        }

                        // Quick suggestions (when input is empty and not processing)
                        if shouldShowQuickSuggestions {
                            quickSuggestionsView
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

    private var shouldShowQuickSuggestions: Bool {
        viewModel.inputText.isEmpty &&
        !viewModel.isProcessing &&
        !viewModel.showTaskReview &&
        !viewModel.showTaskCreationCard &&
        viewModel.currentClarification == nil &&
        viewModel.currentActionResult == nil &&
        viewModel.disambiguationTasks == nil
    }

    // MARK: - Chat Messages

    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: MZSpacing.sm) {
                    ForEach(viewModel.messages) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }

                    // Typing indicator
                    if viewModel.isProcessing {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(MZSpacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to bottom on new message
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isProcessing) { _, isProcessing in
                if isProcessing {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Quick Suggestions

    private var quickSuggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MZSpacing.sm) {
                ForEach(viewModel.quickSuggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.useQuickSuggestion(suggestion)
                        isInputFocused = true
                    } label: {
                        Text(suggestion)
                            .font(MZTypography.labelMedium)
                            .foregroundColor(themeManager.primaryColor)
                            .padding(.horizontal, MZSpacing.sm)
                            .padding(.vertical, MZSpacing.xs)
                            .background(
                                Capsule()
                                    .fill(themeManager.primaryColor.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.xs)
        }
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
        HStack(spacing: MZSpacing.sm) {
            // Text field
            TextField("اكتب مهمتك...", text: $viewModel.inputText)
                .font(MZTypography.bodyLarge)
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, MZSpacing.md)
                .padding(.vertical, MZSpacing.sm)
                .background(themeManager.surfaceSecondaryColor)
                .cornerRadius(24)
                .focused($isInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                }
                .disabled(viewModel.isProcessing)

            // Send button
            Button {
                sendMessage()
            } label: {
                Image(systemName: viewModel.isProcessing ? "hourglass" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        viewModel.inputText.isEmpty || viewModel.isProcessing
                            ? themeManager.textTertiaryColor
                            : themeManager.primaryColor
                    )
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
        }
        .padding(.horizontal, MZSpacing.md)
        .padding(.vertical, MZSpacing.sm)
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

// MARK: - Chat Message Bubble

struct ChatMessageBubble: View {
    let message: ChatMessage
    @EnvironmentObject var themeManager: ThemeManager

    private var isUser: Bool {
        message.role == .user
    }

    /// Parse markdown to AttributedString
    private func markdownText(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: MZSpacing.xxs) {
                // Use markdown-aware text for assistant messages
                if isUser {
                    Text(message.content)
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .padding(.horizontal, MZSpacing.sm)
                        .padding(.vertical, MZSpacing.xs)
                        .background(themeManager.primaryColor)
                        .cornerRadius(18)
                } else {
                    // Render markdown for assistant messages
                    Text(markdownText(message.content))
                        .font(MZTypography.bodyMedium)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .padding(.horizontal, MZSpacing.sm)
                        .padding(.vertical, MZSpacing.xs)
                        .background(themeManager.surfaceSecondaryColor)
                        .cornerRadius(18)
                        .textSelection(.enabled)
                }

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(MZTypography.labelSmall)
                    .foregroundColor(themeManager.textTertiaryColor)
            }

            if !isUser { Spacer(minLength: 50) }
        }
        // Keep chat bubble alignment standard (user right, AI left) regardless of RTL
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dotScale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack {
            HStack(spacing: MZSpacing.xxs) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(themeManager.textSecondaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, MZSpacing.md)
            .padding(.vertical, MZSpacing.sm)
            .background(themeManager.surfaceSecondaryColor)
            .cornerRadius(18)

            Spacer()
        }
        // Keep typing indicator on left (AI side) regardless of RTL
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            animateDots()
        }
    }

    private func animateDots() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever()
                .delay(Double(i) * 0.15)
            ) {
                dotScale[i] = 1.3
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AIChatSheet()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
}
