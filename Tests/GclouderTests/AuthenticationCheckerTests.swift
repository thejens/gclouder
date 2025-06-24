import XCTest
@testable import Gclouder

class MockAuthenticationCheckerDelegate: AuthenticationCheckerDelegate {
    var authStatusChanged = false
    var lastAuthStatus: Bool?
    
    func authenticationStatusChanged(isAuthenticated: Bool) {
        authStatusChanged = true
        lastAuthStatus = isAuthenticated
    }
}

final class AuthenticationCheckerTests: XCTestCase {
    var authChecker: AuthenticationChecker!
    var mockDelegate: MockAuthenticationCheckerDelegate!
    
    override func setUp() {
        super.setUp()
        authChecker = AuthenticationChecker()
        mockDelegate = MockAuthenticationCheckerDelegate()
        authChecker.delegate = mockDelegate
    }
    
    override func tearDown() {
        authChecker = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testDelegateIsWeak() {
        weak var weakDelegate = mockDelegate
        authChecker.delegate = mockDelegate
        mockDelegate = nil
        
        XCTAssertNil(weakDelegate)
        XCTAssertNil(authChecker.delegate)
    }
    
    func testCheckAuthenticationNotifiesDelegate() {
        let expectation = XCTestExpectation(description: "Auth check completes")
        
        authChecker.checkAuthentication()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertTrue(self.mockDelegate.authStatusChanged)
            XCTAssertNotNil(self.mockDelegate.lastAuthStatus)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
} 