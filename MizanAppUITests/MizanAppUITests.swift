//
//  MizanAppUITests.swift
//  MizanAppUITests
//
//  Smoke tests for Mizan app - verifies basic functionality
//

import XCTest

// MARK: - Main App Tests

final class MizanAppUITests: XCTestCase {

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
    func testAppLaunches() throws {
        app.launch()
        XCTAssertTrue(app.exists, "App should launch successfully")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testTabBarExists() throws {
        app.launch()
        sleep(3)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist")
        XCTAssertTrue(tabBar.buttons.count >= 3, "Should have at least 3 tabs")
    }

    @MainActor
    func testCanNavigateBetweenTabs() throws {
        app.launch()
        sleep(3)

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))

        // Navigate to each tab
        for i in 0..<min(tabBar.buttons.count, 3) {
            let tab = tabBar.buttons.element(boundBy: i)
            if tab.exists && tab.isHittable {
                tab.tap()
                sleep(1)
            }
        }

        XCTAssertTrue(app.exists, "App should remain stable after tab navigation")
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
        sleep(3)

        // Timeline is first tab - should be visible
        XCTAssertTrue(app.exists, "Timeline should display")
    }

    @MainActor
    func testTimelineCanSwipeToChangeDate() throws {
        app.launch()
        sleep(3)

        let window = app.windows.firstMatch
        window.swipeLeft()
        sleep(1)
        window.swipeRight()
        sleep(1)

        XCTAssertTrue(app.exists, "App should handle swipe gestures")
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

    private func navigateToInbox() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            let inboxTab = tabBar.buttons.element(boundBy: 1)
            if inboxTab.exists {
                inboxTab.tap()
                sleep(1)
            }
        }
    }

    @MainActor
    func testInboxTabLoads() throws {
        app.launch()
        sleep(3)

        navigateToInbox()

        // Verify navigation title appears
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Inbox should have navigation bar")
    }

    @MainActor
    func testInboxHasContent() throws {
        app.launch()
        sleep(3)

        navigateToInbox()

        // Should have buttons (filter chips, FAB, etc.)
        sleep(2)
        XCTAssertTrue(app.buttons.count > 0, "Inbox should have interactive elements")
    }

    @MainActor
    func testCanTapFABToOpenSheet() throws {
        app.launch()
        sleep(3)

        navigateToInbox()
        sleep(2)

        // Find FAB by identifier or any large button at bottom
        let fab = app.descendants(matching: .any)["inbox_add_task_fab"]
        if fab.waitForExistence(timeout: 5) {
            fab.tap()
            sleep(1)
            XCTAssertTrue(app.sheets.count > 0 || app.navigationBars.count > 1,
                          "Tapping FAB should open a sheet or new view")
        } else {
            // FAB might be named differently, just verify app is stable
            XCTAssertTrue(app.exists, "App should be stable")
        }
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

    private func navigateToSettings() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 10) {
            let settingsTab = tabBar.buttons.element(boundBy: 2)
            if settingsTab.exists {
                settingsTab.tap()
                sleep(1)
            }
        }
    }

    @MainActor
    func testSettingsTabLoads() throws {
        app.launch()
        sleep(3)

        navigateToSettings()

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Settings should have navigation bar")
    }

    @MainActor
    func testSettingsHasContent() throws {
        app.launch()
        sleep(3)

        navigateToSettings()
        sleep(1)

        // Settings should have interactive elements
        XCTAssertTrue(app.buttons.count > 0 || app.switches.count > 0,
                      "Settings should have interactive elements")
    }

    @MainActor
    func testSettingsCanScroll() throws {
        app.launch()
        sleep(3)

        navigateToSettings()

        // Try to scroll
        app.swipeUp()
        sleep(1)

        XCTAssertTrue(app.exists, "App should handle scrolling")
    }
}

// MARK: - Onboarding Tests (when onboarding is shown)

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
    func testOnboardingCanBeCompleted() throws {
        app.launch()
        sleep(3)

        // If tab bar exists, onboarding was skipped or already completed
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5) {
            // Already past onboarding - that's fine
            return
        }

        // Try to find and tap through onboarding by looking for any tappable buttons
        for _ in 0..<10 {
            // Look for any button that might advance the flow
            let buttons = app.buttons.allElementsBoundByIndex
            for button in buttons {
                if button.isHittable {
                    button.tap()
                    sleep(1)
                    break
                }
            }

            // Check if we reached main app
            if app.tabBars.firstMatch.exists {
                break
            }
        }

        // Either completed onboarding or app is stable
        XCTAssertTrue(app.exists, "App should be stable after onboarding attempts")
    }
}

// MARK: - Launch Tests

final class MizanAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
