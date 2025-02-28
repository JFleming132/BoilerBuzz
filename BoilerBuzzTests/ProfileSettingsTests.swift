//
//  ProfileSettingsTests.swift
//  BoilerBuzz
//
//  Created by Patrick Barry on 2/27/25.
//

import XCTest
@testable import BoilerBuzz

// MARK: - MockURLProtocol

class MockURLProtocol: URLProtocol {
    /// This closure is used to provide a custom response for intercepted requests.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    // Intercept all requests.
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    // Return the canonical version of the request.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    // Start loading the request.
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is not set.")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    // Stop loading the request.
    override func stopLoading() {
        // Nothing to do here.
    }
}

// MARK: - ProfileSettingsTests

final class ProfileSettingsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Register our custom URLProtocol.
        URLProtocol.registerClass(MockURLProtocol.self)
    }
    
    override func tearDown() {
        // Unregister our custom URLProtocol.
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }
    
    func testFetchUserProfileSuccess() {
        // Arrange
        let expectedUsername = "TestUser"
        let expectedBio = "Test bio"
        let expectedIsAdmin = false
        let expectedIsBanned = false
        
        let jsonString = """
        {
            "username": "\(expectedUsername)",
            "bio": "\(expectedBio)",
            "isAdmin": \(expectedIsAdmin),
            "isBanned": \(expectedIsBanned)
        }
        """
        let data = jsonString.data(using: .utf8)!
        
        // Set our mock request handler.
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: 200,
                                           httpVersion: nil,
                                           headerFields: nil)!
            return (response, data)
        }
        
        let viewModel = ProfileViewModel()
        let expectation = self.expectation(description: "Fetch profile")
        
        // Act: call the fetch function.
        viewModel.fetchUserProfile(userId: "dummyId")
        
        // Wait a moment for the async operation to complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Assert
            XCTAssertEqual(viewModel.username, expectedUsername, "Username should match expected value")
            XCTAssertEqual(viewModel.bio, expectedBio, "Bio should match expected value")
            XCTAssertEqual(viewModel.isAdmin, expectedIsAdmin, "isAdmin should be false")
            XCTAssertEqual(viewModel.isBanned, expectedIsBanned, "isBanned should be false")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // Additional tests (e.g., error handling) could be added here.
    
    func testFetchUserProfileFailure() {
        // Arrange: Simulate a network error.
        MockURLProtocol.requestHandler = { request in
            throw NSError(domain: "TestError", code: 500, userInfo: nil)
        }
        
        let viewModel = ProfileViewModel()
        let expectation = self.expectation(description: "Fetch profile failure")
        
        // Act
        viewModel.fetchUserProfile(userId: "dummyId")
        
        // For this test, since our code only prints error (and doesn't update properties),
        // we can check that the properties remain unchanged.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(viewModel.username, "Loading...", "Username should remain default on failure")
            XCTAssertEqual(viewModel.bio, "Loading...", "Bio should remain default on failure")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}
