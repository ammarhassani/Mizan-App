//
//  MizanApp.swift
//  Mizan
//
//  Main app entry point
//

import SwiftUI
import SwiftData

@main
struct MizanApp: App {
    // MARK: - App Environment
    @StateObject private var appEnvironment = AppEnvironment.shared

    // MARK: - App State
    @State private var isInitializing = true
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    SplashScreen()
                        .environmentObject(appEnvironment.themeManager)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(appEnvironment)
                        .environmentObject(appEnvironment.themeManager)
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
        print("🚀 Mizan app launching...")

        // Short splash screen duration - just enough for animation reveal
        async let splashDelay: () = _Concurrency.Task.sleep(nanoseconds: 600_000_000) // 0.6 second

        // Initialize app environment
        async let initialization: () = appEnvironment.initialize()

        // Wait for both to complete
        _ = try? await (splashDelay, initialization)

        // Fade out splash screen
        withAnimation(.easeOut(duration: 0.4)) {
            isInitializing = false
        }

        print("✅ Mizan app ready")
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
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Timeline Tab
            TimelineView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .tabItem {
                    Label("الجدول", systemImage: "calendar")
                }
                .tag(0)

            // Inbox Tab
            InboxView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .tabItem {
                    Label("المهام", systemImage: "tray.fill")
                }
                .tag(1)

            // Settings Tab
            SettingsView()
                .environmentObject(appEnvironment)
                .environmentObject(themeManager)
                .tabItem {
                    Label("الإعدادات", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(themeManager.primaryColor)
    }
}



// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppEnvironment.preview())
        .environmentObject(AppEnvironment.preview().themeManager)
        .modelContainer(AppEnvironment.preview().modelContainer)
}
