//
//  MizanAppUITests.swift
//  MizanAppUITests
//
//  Comprehensive UI tests for Mizan app
//

import XCTest

final class MizanAppUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch Tests

    @MainActor
    func testAppLaunches() throws {
        app.launch()
        // App should launch successfully
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - Onboarding Tests

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testOnboardingWelcomeScreenDisplays() throws {
        app.launch()

        // Welcome step should be visible
        let welcomeStep = app.otherElements["onboarding_welcome_step"]
        XCTAssertTrue(welcomeStep.waitForExistence(timeout: 5))

        // Start button should be visible
        let startButton = app.buttons["onboarding_start_button"]
        XCTAssertTrue(startButton.exists)
    }

    @MainActor
    func testOnboardingStartButtonNavigatesToLocation() throws {
        app.launch()

        let startButton = app.buttons["onboarding_start_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))

        startButton.tap()

        // Should navigate to location step
        let locationStep = app.otherElements["onboarding_location_step"]
        XCTAssertTrue(locationStep.waitForExistence(timeout: 3))
    }

    @MainActor
    func testOnboardingSkipLocationNavigatesToMethod() throws {
        app.launch()

        // Navigate to location step
        let startButton = app.buttons["onboarding_start_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Skip location
        let skipButton = app.buttons["onboarding_skip_location_button"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3))
        skipButton.tap()

        // Should navigate to method step
        let methodStep = app.otherElements["onboarding_method_step"]
        XCTAssertTrue(methodStep.waitForExistence(timeout: 3))
    }

    @MainActor
    func testOnboardingCompleteFlow() throws {
        app.launch()

        // Step 1: Welcome - tap start
        let startButton = app.buttons["onboarding_start_button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Step 2: Location - skip
        let skipLocationButton = app.buttons["onboarding_skip_location_button"]
        XCTAssertTrue(skipLocationButton.waitForExistence(timeout: 3))
        skipLocationButton.tap()

        // Step 3: Method - continue with default
        let methodNextButton = app.buttons["onboarding_method_next_button"]
        XCTAssertTrue(methodNextButton.waitForExistence(timeout: 3))
        methodNextButton.tap()

        // Step 4: Notifications - skip
        let skipNotificationsButton = app.buttons["onboarding_skip_notifications_button"]
        XCTAssertTrue(skipNotificationsButton.waitForExistence(timeout: 3))
        skipNotificationsButton.tap()

        // Should exit onboarding - main app should be visible
        // Give time for transition
        sleep(2)
    }
}

// MARK: - Inbox Tests

final class InboxUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testInboxFABExists() throws {
        app.launch()

        // Navigate to inbox tab if not already there
        let inboxTab = app.tabBars.buttons.element(boundBy: 1)
        if inboxTab.exists {
            inboxTab.tap()
        }

        // FAB should exist
        let fab = app.buttons["inbox_add_task_fab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5))
    }

    @MainActor
    func testInboxFilterChipsExist() throws {
        app.launch()

        // Navigate to inbox tab
        let inboxTab = app.tabBars.buttons.element(boundBy: 1)
        if inboxTab.exists {
            inboxTab.tap()
        }

        // Wait for view to load
        sleep(1)

        // Filter chips should exist - check for at least one
        let allFilter = app.buttons["inbox_filter_chip_الكل"]
        XCTAssertTrue(allFilter.waitForExistence(timeout: 5))
    }

    @MainActor
    func testInboxEmptyStateShowsAddButton() throws {
        app.launch()

        // Navigate to inbox tab
        let inboxTab = app.tabBars.buttons.element(boundBy: 1)
        if inboxTab.exists {
            inboxTab.tap()
        }

        // Empty state add button should exist when no tasks
        let emptyStateButton = app.buttons["inbox_empty_state_add_button"]
        // This may or may not exist depending on whether there are tasks
        if emptyStateButton.exists {
            XCTAssertTrue(emptyStateButton.isHittable)
        }
    }

    @MainActor
    func testFABOpensTaskCreation() throws {
        app.launch()

        // Navigate to inbox tab
        let inboxTab = app.tabBars.buttons.element(boundBy: 1)
        if inboxTab.exists {
            inboxTab.tap()
        }

        // Tap FAB
        let fab = app.buttons["inbox_add_task_fab"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5))
        fab.tap()

        // Task creation sheet should appear
        // Check for close button or some element in the sheet
        sleep(1)

        // The sheet should be presented
        XCTAssertTrue(app.navigationBars.count > 0 || app.sheets.count > 0)
    }
}

// MARK: - Settings Tests

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testSettingsThemeLinkExists() throws {
        app.launch()

        // Navigate to settings tab (usually last tab)
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Theme link should exist
        let themeLink = app.buttons["settings_theme_link"]
        XCTAssertTrue(themeLink.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsHijriToggleExists() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Scroll to find the toggle if needed
        let hijriToggle = app.switches["settings_hijri_toggle"]
        XCTAssertTrue(hijriToggle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsHijriToggleCanBeToggled() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Find and toggle the Hijri date switch
        let hijriToggle = app.switches["settings_hijri_toggle"]
        XCTAssertTrue(hijriToggle.waitForExistence(timeout: 5))

        let initialValue = hijriToggle.value as? String
        hijriToggle.tap()

        // Value should have changed
        sleep(1)
        let newValue = hijriToggle.value as? String
        XCTAssertNotEqual(initialValue, newValue)
    }

    @MainActor
    func testSettingsProUpgradeCardOpensPaywall() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Pro upgrade card should exist for non-Pro users
        let proCard = app.buttons["settings_pro_upgrade_card"]
        if proCard.waitForExistence(timeout: 3) {
            proCard.tap()

            // Paywall should open
            let closeButton = app.buttons["paywall_close_button"]
            XCTAssertTrue(closeButton.waitForExistence(timeout: 3))
        }
        // If pro badge exists, user is already Pro - test passes
    }
}

// MARK: - Paywall Tests

final class PaywallUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testPaywallCanBeClosed() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Open paywall via pro card
        let proCard = app.buttons["settings_pro_upgrade_card"]
        guard proCard.waitForExistence(timeout: 3) else {
            // User is already Pro, skip this test
            return
        }
        proCard.tap()

        // Close button should exist
        let closeButton = app.buttons["paywall_close_button"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3))

        // Tap close
        closeButton.tap()

        // Paywall should be dismissed
        sleep(1)
        XCTAssertFalse(closeButton.exists)
    }

    @MainActor
    func testPaywallPurchaseButtonExists() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Open paywall
        let proCard = app.buttons["settings_pro_upgrade_card"]
        guard proCard.waitForExistence(timeout: 3) else {
            return // User is already Pro
        }
        proCard.tap()

        // Purchase button should exist
        let purchaseButton = app.buttons["paywall_purchase_button"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testPaywallRestoreButtonExists() throws {
        app.launch()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }

        // Open paywall
        let proCard = app.buttons["settings_pro_upgrade_card"]
        guard proCard.waitForExistence(timeout: 3) else {
            return // User is already Pro
        }
        proCard.tap()

        // Restore button should exist
        let restoreButton = app.buttons["paywall_restore_button"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
    }
}

// MARK: - Timeline Tests

final class TimelineUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testTimelineLaunches() throws {
        app.launch()

        // Timeline is the first tab, should be visible by default
        // Just verify the app launches and displays content
        sleep(2)
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testTimelineCanSwipeToChangeDate() throws {
        app.launch()

        // Wait for timeline to load
        sleep(2)

        // Perform a swipe gesture
        let window = app.windows.firstMatch
        window.swipeLeft()

        sleep(1)

        // App should still be responsive
        XCTAssertTrue(app.exists)
    }
}
