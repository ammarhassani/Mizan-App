//
//  MizanApp.swift
//  Mizan
//
//  Main app entry point
//

import SwiftUI
import SwiftData
import os.log

@main
struct MizanApp: App {
    // MARK: - App Environment
    @StateObject private var appEnvironment = AppEnvironment.shared

    // MARK: - App State
    @State private var isInitializing = true
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - UI Testing Support
    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    private static var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--skip-onboarding")
    }

    private static var shouldResetOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-onboarding")
    }

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    SplashScreen()
                        .environmentObject(appEnvironment.themeManager)
                        .environmentObject(DarkMatterTheme.shared)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(appEnvironment)
                        .environmentObject(appEnvironment.themeManager)
                        .environmentObject(DarkMatterTheme.shared)
                        .environmentObject(appEnvironment.locationManager)
                        .environmentObject(appEnvironment.prayerTimeService)
                        .modelContainer(appEnvironment.modelContainer)
                        .rtlSupport(language: appEnvironment.userSettings.language)
                        .preferredColorScheme(appEnvironment.themeManager.colorScheme)
                }
            }
            .task {
                await initializeApp()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && !isInitializing {
                    // Check if we need to reschedule notifications for a new day
                    _Concurrency.Task {
                        await appEnvironment.checkAndRescheduleNotifications()
                    }
                }
            }
        }
    }

    // MARK: - Initialization
    private func initializeApp() async {
        MizanLogger.shared.lifecycle.info("Mizan app launching...")

        // Handle UI testing flags
        if Self.isUITesting {
            MizanLogger.shared.lifecycle.info("Running in UI testing mode")

            if Self.shouldResetOnboarding {
                // Reset onboarding for testing
                appEnvironment.userSettings.hasCompletedOnboarding = false
                appEnvironment.save()
                MizanLogger.shared.lifecycle.info("Onboarding reset for testing")
            } else if Self.shouldSkipOnboarding {
                // Skip onboarding for testing
                appEnvironment.userSettings.hasCompletedOnboarding = true
                appEnvironment.save()
                MizanLogger.shared.lifecycle.info("Onboarding skipped for testing")
            }
        }

        // Short splash screen duration - just enough for animation reveal
        // Skip splash delay in UI testing mode for faster tests
        let splashDuration: UInt64 = Self.isUITesting ? 100_000_000 : 600_000_000
        async let splashDelay: () = _Concurrency.Task.sleep(nanoseconds: splashDuration)

        // Initialize app environment
        async let initialization: () = appEnvironment.initialize()

        // Wait for both to complete
        _ = try? await (splashDelay, initialization)

        // Fade out splash screen
        withAnimation(.easeOut(duration: Self.isUITesting ? 0.1 : 0.4)) {
            isInitializing = false
        }

        MizanLogger.shared.lifecycle.info("Mizan app ready")
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            if appEnvironment.onboardingCompleted {
                // Main app interface
                MainTabView()
            } else {
                // Onboarding flow
                OnboardingView()
                    .environmentObject(appEnvironment.locationManager)
            }
        }
        .background(themeManager.backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Splash Screen (Dramatic)

struct SplashScreen: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var moonRevealed = false
    @State private var starsVisible = false
    @State private var titleRevealed = false
    @State private var glowIntensity: CGFloat = 0

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .environmentObject(themeManager)

            // Floating star particles
            ParticleStarsView()
                .environmentObject(themeManager)
                .opacity(starsVisible ? 1 : 0)

            VStack(spacing: MZSpacing.lg) {
                // Mizan Logo with breathing glow
                ZStack {
                    // Glow effect
                    MizanLogoPillarsShape()
                        .fill(themeManager.splashMoonColor.opacity(0.3))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)
                        .scaleEffect(1 + glowIntensity * 0.2)
                        .opacity(glowIntensity)

                    // Animated Mizan Logo
                    MizanLogoGradient(
                        size: 160,
                        designGradient: LinearGradient(
                            colors: [themeManager.splashTextColor, themeManager.splashMoonColor],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        animated: false,
                        glowColor: themeManager.splashMoonColor,
                        glowIntensity: 0
                    )
                    .scaleEffect(moonRevealed ? 1.0 : 0.3)
                    .opacity(moonRevealed ? 1.0 : 0.0)
                    .shadow(color: themeManager.splashMoonColor.opacity(0.5), radius: 20)
                }

                VStack(spacing: MZSpacing.sm) {
                    // App Name
                    Text("ميزان")
                        .font(MZTypography.displayLarge)
                        .foregroundColor(themeManager.splashTextColor)
                        .opacity(titleRevealed ? 1 : 0)
                        .blur(radius: titleRevealed ? 0 : 10)

                    // Tagline
                    Text("خطط يومك حول ما يهم حقًا")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.splashTextColor.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .opacity(titleRevealed ? 1 : 0)
                        .offset(y: titleRevealed ? 0 : 20)
                }
            }
        }
        .onAppear {
            // Fast choreographed reveal sequence (optimized for shorter splash)
            withAnimation(.easeOut(duration: 0.2)) {
                starsVisible = true
            }
            withAnimation(MZAnimation.dramatic.delay(0.1)) {
                moonRevealed = true
            }
            withAnimation(MZAnimation.gentle.delay(0.25)) {
                titleRevealed = true
            }
            // Start breathing glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.3)) {
                glowIntensity = 1.0
            }
            // Haptic feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticManager.shared.trigger(.medium)
            }
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: themeManager.splashGradientColors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Particle Stars View

struct ParticleStarsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var stars: [Star] = []

    struct Star: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
    }

    var body: some View {
        let starColor = themeManager.splashTextColor

        Canvas { context, size in
            for star in stars {
                let rect = CGRect(
                    x: star.x * size.width,
                    y: star.y * size.height,
                    width: star.size,
                    height: star.size
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(starColor.opacity(star.opacity))
                )
            }
        }
        .onAppear {
            // Generate random stars
            stars = (0..<30).map { _ in
                Star(
                    x: CGFloat.random(in: 0...1),
                    y: CGFloat.random(in: 0...1),
                    size: CGFloat.random(in: 2...6),
                    opacity: Double.random(in: 0.3...0.8)
                )
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedDestination: DockDestination = .timeline

    // Prayer period for background (computed from current time)
    private var currentPrayerPeriod: Int {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<6: return 0   // Fajr
        case 6..<7: return 1   // Sunrise
        case 12..<15: return 2 // Dhuhr
        case 15..<17: return 3 // Asr
        case 17..<19: return 4 // Maghrib
        default: return 5      // Isha
        }
    }

    var body: some View {
        ZStack {
            // Dark Matter background
            DarkMatterBackground(prayerPeriod: currentPrayerPeriod)

            // Main content area
            VStack(spacing: 0) {
                currentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }

            // Dock at bottom
            VStack {
                Spacer()
                EventHorizonDock(selection: $selectedDestination)
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private var currentView: some View {
        switch selectedDestination {
        case .timeline:
            TimelineView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .inbox:
            InboxView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .mizanAI:
            MizanAITab()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)

        case .settings:
            SettingsView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Mizan AI Tab

struct MizanAITab: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showPaywall = false

    var body: some View {
        Group {
            if appEnvironment.userSettings.isPro {
                // Pro users get full AI chat
                AIChatView()
            } else {
                // Non-Pro users see locked state
                MizanAILockedView(onUnlock: { showPaywall = true })
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Mizan AI Locked View (for non-Pro users)

struct MizanAILockedView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: MZSpacing.xl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(themeManager.primaryColor.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundColor(themeManager.primaryColor)
                }

                // Title & Description
                VStack(spacing: MZSpacing.sm) {
                    Text("Mizan AI")
                        .font(MZTypography.headlineLarge)
                        .foregroundColor(themeManager.textPrimaryColor)

                    Text("مساعدك الذكي لإدارة المهام")
                        .font(MZTypography.bodyLarge)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .multilineTextAlignment(.center)
                }

                // Features list
                VStack(alignment: .leading, spacing: MZSpacing.md) {
                    featureRow(icon: "text.bubble.fill", text: "أنشئ مهام بالمحادثة الطبيعية")
                    featureRow(icon: "calendar.badge.clock", text: "جدول مهامك حول أوقات الصلاة")
                    featureRow(icon: "wand.and.stars", text: "تعديل وحذف المهام بالأوامر الصوتية")
                    featureRow(icon: "brain", text: "اقتراحات ذكية لتنظيم يومك")
                }
                .padding(.horizontal, MZSpacing.xl)

                Spacer()

                // Unlock button
                Button {
                    onUnlock()
                } label: {
                    HStack(spacing: MZSpacing.sm) {
                        Image(systemName: "lock.open.fill")
                        Text("فتح Mizan AI")
                    }
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MZSpacing.md)
                    .background(themeManager.primaryColor)
                    .cornerRadius(themeManager.cornerRadius(.large))
                }
                .padding(.horizontal, MZSpacing.screenPadding)

                // Pro badge
                HStack(spacing: MZSpacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("ميزة Pro")
                        .font(MZTypography.labelMedium)
                }
                .foregroundColor(themeManager.warningColor)
                .padding(.bottom, MZSpacing.lg)
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: MZSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 28)

            Text(text)
                .font(MZTypography.bodyMedium)
                .foregroundColor(themeManager.textPrimaryColor)
        }
    }
}

// MARK: - AI Chat View (Full Tab Version)

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    @StateObject private var viewModel: AIChatViewModel

    @FocusState private var isInputFocused: Bool

    init() {
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
                themeManager.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat messages - takes all available space
                    chatMessagesView

                    // Bottom section - cards and input anchored to bottom
                    VStack(spacing: 0) {
                        // V2: Action result card
                        if let result = viewModel.currentActionResult {
                            actionResultSection(result)
                        }

                        // V2: Clarification card - DISABLED (per user request)
                        // if let clarification = viewModel.currentClarification {
                        //     clarificationSection(clarification)
                        // }

                        // V2: Task disambiguation card
                        if let tasks = viewModel.disambiguationTasks,
                           let question = viewModel.disambiguationQuestion {
                            disambiguationSection(question: question, tasks: tasks)
                        }

                        // All-in-one task creation card (when AI detected task with missing fields)
                        if viewModel.showTaskCreationCard, let taskData = viewModel.pendingTaskData {
                            taskCreationSection(taskData)
                        }

                        // Quick suggestions
                        if shouldShowQuickSuggestions {
                            quickSuggestionsView
                        }

                        // Task preview card (V1 compatible)
                        if viewModel.showTaskReview, let task = viewModel.extractedTask {
                            taskPreviewCard(task)
                        }

                        // Input bar
                        inputBarView
                    }
                }
            }
            .navigationTitle("Mizan AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
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
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Computed Properties

    /// Legacy - quick suggestions are now shown in the welcome view
    private var shouldShowQuickSuggestions: Bool {
        false
    }

    // MARK: - Chat Messages

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
            UserMessageView(message: message)
        } else {
            AIMessageView(message: message)
        }
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
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.successColor)
                Text("معاينة المهمة")
                    .font(MZTypography.titleMedium)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }

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
                    _ = viewModel.confirmTask()
                    HapticManager.shared.trigger(.success)
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
    ContentView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .environmentObject(DarkMatterTheme.shared)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
