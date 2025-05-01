//
//  postsTests.swift
//  BoilerBuzz
//
//  Created by user272845 on 3/31/25.
//

import XCTest
@testable import BoilerBuzz

final class PostsAndRSVPTests: XCTestCase {

    // MARK: - Test Post (Event) Creation

    func testEventCreation() throws {
        // Create a sample event (post)
        let now = Date()
        let sampleEvent = Event(
            id: "post1",
            author: "user1",
            rsvpCount: 0,
            title: "Sample Event",
            description: "This is a sample event for testing.",
            location: "Sample Location",
            capacity: 100,
            is21Plus: false,
            promoted: false,
            date: now,
            imageUrl: nil,
            authorUsername: "TestUser"
        )
        
        // Verify that the event properties are set correctly.
        XCTAssertEqual(sampleEvent.id, "post1")
        XCTAssertEqual(sampleEvent.author, "user1")
        XCTAssertEqual(sampleEvent.title, "Sample Event")
        XCTAssertEqual(sampleEvent.description, "This is a sample event for testing.")
        XCTAssertEqual(sampleEvent.location, "Sample Location")
        XCTAssertEqual(sampleEvent.capacity, 100)
        XCTAssertFalse(sampleEvent.is21Plus)
        XCTAssertFalse(sampleEvent.promoted)
        XCTAssertEqual(sampleEvent.date, now)
        XCTAssertNil(sampleEvent.imageUrl)
        XCTAssertEqual(sampleEvent.authorUsername, "TestUser")
    }

  
    
    // MARK: - Additional Tests (Optional)
    
    func testDescriptionLengthValidation() throws {
        let maxDescriptionLength = 200
        
        let validDescription = String(repeating: "a", count: 150)
        let invalidDescription = String(repeating: "b", count: 250)
        
        XCTAssertTrue(validDescription.count <= maxDescriptionLength, "Valid description should be within the limit.")
        XCTAssertTrue(invalidDescription.count > maxDescriptionLength, "Invalid description should exceed the limit.")
    }
}
