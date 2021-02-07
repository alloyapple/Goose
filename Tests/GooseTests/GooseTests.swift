import XCTest
@testable import Goose

final class GooseTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Goose().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
