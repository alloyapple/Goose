import XCTest

@testable import Goose

final class GooseTests: XCTestCase {
    func testSocket() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(priority: .background).async {
            let server = Socket()
            do {
                try server.bind(hostname: "0.0.0.0", port: 8999)
                try server.listen()
                let client = try server.accept()
            } catch SocketError.message(let msg) {
                XCTAssert(false, "异常错误: \(msg)")
            } catch {
                XCTAssert(false, "未知错误")
            }

        }

        DispatchQueue.global(priority: .high).async {
            let client = Socket()
            do {
                try client.connect(hostname: "127.0.0.1", port: 8999)
            } catch SocketError.message(let msg) {
                XCTAssert(false, "异常错误: \(msg)")
            } catch {
                XCTAssert(false, "链接错误")
            }

            group.leave()
        }

        _ = group.wait(timeout: .now() + 4)
    }

    static var allTests = [
        ("测试socket", testSocket)
    ]
}
