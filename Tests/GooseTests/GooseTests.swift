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
                server.options.reuseAddress = true
                try server.bind(hostname: "0.0.0.0", port: 8999)
                try server.listen()
                let client = try server.accept()
                _ = try client.write("hello world")
            } catch GooseError.message(let msg) {
                XCTAssert(false, "异常错误: \(msg)")
            } catch {
                XCTAssert(false, "未知错误")
            }

        }

        DispatchQueue.global(priority: .high).async {
            let client = Socket()
            do {
                client.options.reuseAddress = true
                try client.connect(hostname: "127.0.0.1", port: 8999)
                let str = try client.read(100).asString ?? ""

                XCTAssertEqual(str, "hello world")

            } catch GooseError.message(let msg) {
                XCTAssert(false, "异常错误: \(msg)")
            } catch {
                XCTAssert(false, "链接错误")
            }

            group.leave()
        }

        _ = group.wait(timeout: .now() + 4)
    }

    func testGetAddrinfo() {
        do {
            let r = try getAddrinfo(host: "www.163.com", port: 80)

            for _ in r {

            }
        } catch {

        }
    }

    func testData() {
        releaseLog("测试testData")
        let data = Data("hello \n 你 \n world".utf8)
        let line = data.readLine()
        XCTAssertEqual(line, [104, 101, 108, 108, 111, 32, 10])

        let lines = data.readLines()
        for (i, line) in lines.enumerated() {
            if i == 0 {
                XCTAssertEqual(line, [104, 101, 108, 108, 111, 32, 10])
            } else if i == 1 {
                XCTAssertEqual(line, [32, 228, 189, 160, 32, 10])
            }
        }
    }

    static var allTests = [
        ("测试socket", testSocket),
        ("测试Data扩展", testData),
        ("测试GetAddrInfo", testGetAddrinfo),
    ]
}
