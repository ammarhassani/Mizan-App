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

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    SplashScreen()
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
        }
    }

    // MARK: - Initialization
    private func initializeApp() async {
        print("🚀 Mizan app launching...")

        // Simulate splash screen duration (minimum display time)
        async let splashDelay: () = _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Initialize app environment
        async let initialization: () = appEnvironment.initialize()

        // Wait for both to complete
        _ = try? await (splashDelay, initialization)

        // Fade out splash screen
        withAnimation(.easeOut(duration: 0.3)) {
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

// MARK: - Splash Screen

struct SplashScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#14746F"),
                    Color(hex: "#52B788")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon/Logo
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)

                // App Name
                Text("ميزان")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)

                // Tagline
                Text("خطط يومك حول ما يهم حقًا")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(opacity)
                    .padding(.horizontal, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
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
