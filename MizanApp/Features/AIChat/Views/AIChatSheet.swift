//
//  AIChatSheet.swift
//  Mizan
//
//  AI-powered chat interface for natural language task creation
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

    // Callback when task is created
    var onTaskCreated: ((Task) -> Void)?

    init(onTaskCreated: ((Task) -> Void)? = nil) {
        self.onTaskCreated = onTaskCreated
        // ViewModel will be initialized in onAppear
        _viewModel = StateObject(wrappedValue: AIChatViewModel(
            aiService: AppEnvironment.shared.aiTaskService,
            modelContext: AppEnvironment.shared.modelContainer.mainContext,
            userSettings: AppEnvironment.shared.userSettings
        ))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat messages
                    chatMessagesView

                    // Quick suggestions (when input is empty and not processing)
                    if viewModel.inputText.isEmpty && !viewModel.isProcessing && !viewModel.showTaskReview {
                        quickSuggestionsView
                    }

                    // Task preview card (when task is extracted)
                    if viewModel.showTaskReview, let task = viewModel.extractedTask {
                        taskPreviewCard(task)
                    }

                    // Input bar
                    inputBarView
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
        }
        .interactiveDismissDisabled(viewModel.isProcessing)
    }

    // MARK: - Chat Messages

    private var chatMessagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
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
                .padding()
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
            HStack(spacing: 8) {
                ForEach(viewModel.quickSuggestions, id: \.self) { suggestion in
                    Button {
                        viewModel.useQuickSuggestion(suggestion)
                        isInputFocused = true
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.primaryColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(themeManager.primaryColor.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(themeManager.surfaceColor)
    }

    // MARK: - Task Preview Card

    private func taskPreviewCard(_ task: ExtractedTaskData) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.successColor)
                Text("معاينة المهمة")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }

            // Task details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: TaskIconDetector.shared.detectIcon(from: task.title))
                        .foregroundColor(themeManager.primaryColor)
                    Text(task.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.textPrimaryColor)
                }

                HStack(spacing: 16) {
                    if let date = task.scheduledDate {
                        Label(date, systemImage: "calendar")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    if let time = task.scheduledTime {
                        Label(time, systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.textSecondaryColor)
                    }

                    Label("\(task.duration) د", systemImage: "timer")
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.textSecondaryColor)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button {
                    viewModel.cancelExtraction()
                } label: {
                    Text("إلغاء")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.textSecondaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(themeManager.primaryColor)
                    .cornerRadius(themeManager.cornerRadius(.medium))
                }
            }
        }
        .padding()
        .background(themeManager.surfaceColor)
        .cornerRadius(themeManager.cornerRadius(.large))
        .shadow(color: themeManager.textPrimaryColor.opacity(0.1), radius: 8, y: 4)
        .padding()
    }

    // MARK: - Input Bar

    private var inputBarView: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("اكتب مهمتك...", text: $viewModel.inputText)
                .font(.system(size: 16))
                .foregroundColor(themeManager.textPrimaryColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(themeManager.surfaceColor)
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

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isUser ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser
                            ? themeManager.primaryColor
                            : themeManager.surfaceSecondaryColor
                    )
                    .cornerRadius(18)

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(themeManager.textTertiaryColor)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dotScale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(themeManager.textSecondaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(themeManager.surfaceSecondaryColor)
            .cornerRadius(18)

            Spacer()
        }
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
