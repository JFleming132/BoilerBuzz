//
//  BoilerBuzzUITests.swift
//  BoilerBuzzUITests
//
//  Created by user269394 on 2/5/25.
//

import XCTest

final class BoilerBuzzUITests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMapPageDisplaysMapAfterLogin() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before interacting with the app
        // such as logging into a test account

        // Ensure login fields exist
        let usernameField = app.textFields["UsernameField"]
        let passwordField = app.secureTextFields["PasswordField"]
        let loginButton = app.buttons["LoginButton"]

        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username field should exist")
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        XCTAssertTrue(loginButton.exists, "Login button should exist")

        // Perform login
        usernameField.tap()
        usernameField.typeText("testing69@purdue.edu") // Replace with test credentials

        passwordField.tap()
        passwordField.typeText("test") // Replace with test password

        loginButton.tap()

        // Wait for navigation to the home screen
        let mapTab = app.buttons["Map"] // Replace with actual identifier
        XCTAssertTrue(mapTab.waitForExistence(timeout: 5), "Map tab should exist after login")

        // Navigate to the Map Page
        mapTab.tap()

        // Verify if the Map appears
        let mapElement = app.otherElements["MapView"] // Replace with actual identifier
        XCTAssertTrue(mapElement.waitForExistence(timeout: 5), "MapView should be visible on the map page.")
        
        // Take a screenshot of the map page
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Map Page"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testWrongCurrPasswordUpdate() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()

        // Login process
        let usernameField = app.textFields["UsernameField"]
        let passwordField = app.secureTextFields["PasswordField"]
        let loginButton = app.buttons["LoginButton"]

        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username field should exist")
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        XCTAssertTrue(loginButton.exists, "Login button should exist")

        usernameField.tap()
        usernameField.typeText("testing69@purdue.edu")

        passwordField.tap()
        passwordField.typeText("test")

        loginButton.tap()

        // Navigate to the profile or settings page
        let profileButton = app.buttons["Account"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 5), "Account button should exist")
        profileButton.tap()

        // Find and tap the "Change Password" button
        let changePasswordButton = app.buttons["Settings"]
        XCTAssertTrue(changePasswordButton.waitForExistence(timeout: 5), "Change Password button should exist")
        changePasswordButton.tap()
        
        // Find and tap the "Change Password" button
        let changePasswordButton2 = app.buttons["Password"]
        XCTAssertTrue(changePasswordButton2.waitForExistence(timeout: 5), "Change Password button should exist")
        changePasswordButton2.tap()
        
        // Enter incorrect current password and new password
        let currentPasswordField = app.secureTextFields["Current Password"]
        let newPasswordField = app.secureTextFields["New Password"]
        let confirmNewPasswordField = app.secureTextFields["Confirm New Password"]

        XCTAssertTrue(currentPasswordField.waitForExistence(timeout: 5), "Current Password field should exist")
        XCTAssertTrue(newPasswordField.exists, "New Password field should exist")
        XCTAssertTrue(confirmNewPasswordField.exists, "Confirm New Password field should exist")

        currentPasswordField.tap()
        currentPasswordField.typeText("a")

        newPasswordField.tap()
        newPasswordField.typeText("newpassword")

        confirmNewPasswordField.tap()
        confirmNewPasswordField.typeText("newpassword")

        // Tap the update password button
        let updatePasswordButton = app.buttons["Update Password"]
        XCTAssertTrue(updatePasswordButton.waitForExistence(timeout: 5), "Update Password button should exist")
            updatePasswordButton.tap()
        // Assert that the error alert is displayed
        let errorAlert = app.alerts["Password Update"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Error alert should be displayed")

            // Check for the error message
        let errorMessage = errorAlert.staticTexts.element(boundBy: 0).label
        print("Error message from alert: \(errorMessage)")
        XCTAssertTrue(errorMessage.contains("Password Update"), "Error message should indicate invalid old password")

            // Dismiss the alert
        errorAlert.buttons["OK"].tap()
        
        // Verify that the password fields are not cleared
        XCTAssertFalse(currentPasswordField.value as! String == "", "Current password field should not be cleared")
        XCTAssertFalse(newPasswordField.value as! String == "", "New password field should not be cleared")
        XCTAssertFalse(confirmNewPasswordField.value as! String == "", "Confirm new password field should not be cleared")
    }

    func testDiffNewPasswordUpdate() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()

        // Login process
        let usernameField = app.textFields["UsernameField"]
        let passwordField = app.secureTextFields["PasswordField"]
        let loginButton = app.buttons["LoginButton"]

        XCTAssertTrue(usernameField.waitForExistence(timeout: 5), "Username field should exist")
        XCTAssertTrue(passwordField.exists, "Password field should exist")
        XCTAssertTrue(loginButton.exists, "Login button should exist")

        usernameField.tap()
        usernameField.typeText("testing69@purdue.edu")

        passwordField.tap()
        passwordField.typeText("test")

        loginButton.tap()

        // Navigate to the profile or settings page
        let profileButton = app.buttons["Account"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 5), "Account button should exist")
        profileButton.tap()

        // Find and tap the "Change Password" button
        let changePasswordButton = app.buttons["Settings"]
        XCTAssertTrue(changePasswordButton.waitForExistence(timeout: 5), "Change Password button should exist")
        changePasswordButton.tap()
        
        // Find and tap the "Change Password" button
        let changePasswordButton2 = app.buttons["Password"]
        XCTAssertTrue(changePasswordButton2.waitForExistence(timeout: 5), "Change Password button should exist")
        changePasswordButton2.tap()
        
        // Enter incorrect current password and new password
        let currentPasswordField = app.secureTextFields["Current Password"]
        let newPasswordField = app.secureTextFields["New Password"]
        let confirmNewPasswordField = app.secureTextFields["Confirm New Password"]

        XCTAssertTrue(currentPasswordField.waitForExistence(timeout: 5), "Current Password field should exist")
        XCTAssertTrue(newPasswordField.exists, "New Password field should exist")
        XCTAssertTrue(confirmNewPasswordField.exists, "Confirm New Password field should exist")

        currentPasswordField.tap()
        currentPasswordField.typeText("test")

        newPasswordField.tap()
        newPasswordField.typeText("newpassword1")

        confirmNewPasswordField.tap()
        confirmNewPasswordField.typeText("newpassword2")

        // Tap the update password button
        let updatePasswordButton = app.buttons["Update Password"]
        XCTAssertTrue(updatePasswordButton.waitForExistence(timeout: 5), "Update Password button should exist")
            updatePasswordButton.tap()
        // Assert that the error alert is displayed
        let errorAlert = app.alerts["Password Update"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Error alert should be displayed")

            // Check for the error message
        let errorMessage = errorAlert.staticTexts.element(boundBy: 0).label
        print("Error message from alert: \(errorMessage)")
        XCTAssertTrue(errorMessage.contains("Password Update"), "Error message should indicate invalid old password")

            // Dismiss the alert
        errorAlert.buttons["OK"].tap()
        
        // Verify that the password fields are not cleared
        XCTAssertFalse(currentPasswordField.value as! String == "", "Current password field should not be cleared")
        XCTAssertFalse(newPasswordField.value as! String == "", "New password field should not be cleared")
        XCTAssertFalse(confirmNewPasswordField.value as! String == "", "Confirm new password field should not be cleared")
    }
    }
