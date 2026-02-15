import XCTest

final class StartupUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testSplashDisplayedOnLaunch() throws {
    let app = XCUIApplication()
    app.launch()

    let splash = app.otherElements["StartupSplashView"]
    XCTAssertTrue(splash.waitForExistence(timeout: 2), "Startup splash should be visible on launch")
  }

  func testContinueInBackgroundButtonTappableIfPresent() throws {
    let app = XCUIApplication()
    app.launch()

    let continueButton = app.buttons["ContinueBackgroundButton"]
    if continueButton.waitForExistence(timeout: 2) {
      continueButton.tap()
      XCTAssertFalse(app.otherElements["StartupSplashView"].exists)
    } else {
      // Button may not appear during a fast startup; treat as non-fatal for now
      XCTContext.runActivity(named: "Continue button not present — fast startup") { _ in }
    }
  }
}
