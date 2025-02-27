//
//  BoilerBuzzUITests.swift
//  BoilerBuzzUITests
//
//  Created by user269394 on 2/5/25.
//

import XCTest

final class BoilerBuzzUITests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
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
    
    }
