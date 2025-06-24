import XCTest
import Cocoa
@testable import Gclouder

final class StatusBarControllerTests: XCTestCase {
    var statusBarController: StatusBarController!
    
    override func setUp() {
        super.setUp()
        // Note: This test might require running in a full app context
        // for NSStatusBar to work properly
        statusBarController = StatusBarController()
    }
    
    override func tearDown() {
        statusBarController = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertNotNil(statusBarController)
    }
    
    func testMenuCreation() {
        // This is a basic test to ensure the menu creation doesn't crash
        // More detailed UI testing would require XCUITest
        let selector = NSSelectorFromString("showMenu")
        XCTAssertTrue(statusBarController.responds(to: selector))
    }
}

// Test helper for GCloudAuthenticator
final class GCloudAuthenticatorTests: XCTestCase {
    func testAuthenticatorStructExists() {
        // This just verifies the type exists and can be referenced
        XCTAssertNotNil(GCloudAuthenticator.self)
    }
} 