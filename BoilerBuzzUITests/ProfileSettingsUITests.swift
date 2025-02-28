//
//  ProfileSettingsUITests.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/27/25.
//


import XCTest

// An extension to clear text in a text field.
extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else { return }
        // Select all text and delete it.
        self.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}

final class ProfileSettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        // Optionally, you can pass launch arguments to configure your app for testing.
        app.launchArguments = ["-UITestSkipLogin"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // Test that tapping the settings button shows the settings page.
    func testSettingsPageAppears() {
        // Assume the settings button has the identifier "settingsButton".
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        settingsButton.tap()
        
        // 2. Verify the Settings screen appears by checking for a known element.
        // Assume the Account row in the settings screen has an accessibility identifier "accountSettingsRow".
        let accountRow = app.descendants(matching: .any).matching(identifier: "accountSettingsRow").element
        XCTAssertTrue(accountRow.waitForExistence(timeout: 10), "Account settings row should exist")
        accountRow.tap()
        
        
        // Verify that the Edit Profile screen appears by checking for a label "Edit Profile".
        let editProfileLabel = app.staticTexts["Edit Profile"]
        XCTAssertTrue(editProfileLabel.waitForExistence(timeout: 5), "Edit Profile screen should appear")
    }
    
    // Test that the username text field does not auto-capitalize.
    func testUsernameFieldDoesNotAutoCapitalize() {
        // Navigate to the settings page.
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // 2. Verify the Settings screen appears by checking for a known element.
        // Assume the Account row in the settings screen has an accessibility identifier "accountSettingsRow".
        let accountRow = app.descendants(matching: .any).matching(identifier: "accountSettingsRow").element
        XCTAssertTrue(accountRow.waitForExistence(timeout: 10), "Account settings row should exist")
        accountRow.tap()
        
        // Assume the username TextField has identifier "usernameTextField".
        let usernameField = app.textFields["usernameTextField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username text field should exist")
        
        // Tap the field and type a lowercase letter.
        usernameField.tap()
        usernameField.clearText()
        usernameField.typeText("a")
        
        // Verify that the text remains lowercase.
        // Note: The field's value might be the placeholder if no text exists. Adjust as needed.
        XCTAssertEqual(usernameField.value as? String, "a", "Username should remain lowercase")
    }
    
    // Test that saving invalid profile data (e.g. an empty username) shows an error.
    func testSavingInvalidProfileDataShowsError() {
        // Navigate to the settings page.
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // 2. Verify the Settings screen appears by checking for a known element.
        // Assume the Account row in the settings screen has an accessibility identifier "accountSettingsRow".
        let accountRow = app.descendants(matching: .any).matching(identifier: "accountSettingsRow").element
        XCTAssertTrue(accountRow.waitForExistence(timeout: 10), "Account settings row should exist")
        accountRow.tap()
        
        // Access the username text field.
        let usernameField = app.textFields["usernameTextField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.tap()
        usernameField.clearText()
        
        // Tap the "Done" button. Assume it has identifier "doneButton".
        let doneButton = app.buttons["doneButton"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        
        // Verify that an error message appears in the error label with identifier "errorMessageLabel".
        let errorLabel = app.staticTexts["errorMessageLabel"]
        XCTAssertTrue(errorLabel.waitForExistence(timeout: 5), "Error message should appear for invalid data")
        // Optionally check the text of the error.
        XCTAssertEqual(errorLabel.label, "Username cannot be empty", "Error message should indicate the issue")
    }
}
