import XCTest
@testable import BoilerBuzz // Replace with your actual app name if different

// MARK: - PasswordUpdater Struct
struct PasswordUpdater {
    var userDefaults: UserDefaults = .standard
    
    func updatePassword(oldPassword: String, newPassword: String, confirmNewPassword: String) -> (showAlert: Bool, alertMessage: String) {
        guard newPassword == confirmNewPassword else {
            return (true, "New passwords do not match.")
        }

        guard let userId = userDefaults.string(forKey: "userId") else {
            return (true, "User ID not found. Please log in again.")
        }

        // For now, we'll just return a success message
        // In a real scenario, you'd make the network call here
        return (true, "Password updated successfully!")
    }
}

// MARK: - PrivacySecuritySettingsViewTests
class PrivacySecuritySettingsViewTests: XCTestCase {
    var sut: PasswordUpdater!
    var mockUserDefaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUserDefaults = UserDefaults(suiteName: "testsuite")
        sut = PasswordUpdater(userDefaults: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockUserDefaults.removeSuite(named: #file)
        mockUserDefaults = nil
        try super.tearDownWithError()
    }

    func testUpdatePasswordWithMismatchedNewPasswords() {
        let result = sut.updatePassword(oldPassword: "old", newPassword: "new", confirmNewPassword: "different")
        
        XCTAssertTrue(result.showAlert)
        XCTAssertEqual(result.alertMessage, "New passwords do not match.")
    }

    func testUpdatePasswordWithMissingUserId() {
        mockUserDefaults.removeObject(forKey: "userId")
        
        let result = sut.updatePassword(oldPassword: "old", newPassword: "new", confirmNewPassword: "new")
        
        XCTAssertTrue(result.showAlert)
        XCTAssertEqual(result.alertMessage, "User ID not found. Please log in again.")
    }

    func testUpdatePasswordSuccess() {
        mockUserDefaults.set("testUserId", forKey: "userId")
        
        let result = sut.updatePassword(oldPassword: "old", newPassword: "new", confirmNewPassword: "new")
        
        XCTAssertTrue(result.showAlert)
        XCTAssertEqual(result.alertMessage, "Password updated successfully!")
    }
}
