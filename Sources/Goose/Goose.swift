import Foundation
import Glibc
import GlibcExtra

public func toAddr(_ addr: inout sockaddr_in) -> UnsafeMutablePointer<sockaddr> {
    return withUnsafeMutablePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            $0
        }
    }
}

public func toAddr(_ addr: inout sockaddr_in6) -> UnsafeMutablePointer<sockaddr> {
    return withUnsafeMutablePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            $0
        }
    }
}

public func toAddr(_ addr: inout sockaddr_un) -> UnsafeMutablePointer<sockaddr> {
    return withUnsafeMutablePointer(to: &addr) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            $0
        }
    }
}

extension Data {
    public var asString: String? {
        return String(data: self, encoding: .utf8)
    }
}

extension UnsafeRawPointer {
    public func unretainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeUnretainedValue()
    }

    public func retainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeRetainedValue()
    }
}

extension UnsafeMutableRawPointer {
    public func unretainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeUnretainedValue()
    }

    public func retainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeRetainedValue()
    }
}

extension StringProtocol {
    public var data: Data { .init(utf8) }
    public var bytes: [UInt8] { .init(utf8) }
}

func internalSelect(fd: Int32, writing: Bool = true, ms: Int32 = 1000) throws {
    let ev = writing ? Int16(POLLOUT) : Int16(POLLIN)
    var pollfd = Glibc.pollfd(fd: fd, events: ev, revents: 0)
    let n = poll(&pollfd, 1, ms)

    guard n > 0 else {
        throw GooseError.error()
    }
}



func releaseLog(_ message: String = "called", file: String = #file, function: String = #function) {
	let timestamp = ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone.current, formatOptions: [.withYear, .withMonth, .withDay, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime])
	print("\(timestamp) \(URL(fileURLWithPath: file, isDirectory: false).deletingPathExtension().lastPathComponent): \(function) \(message)")
}

func debugLog(_ message: String = "called", file: String = #file, function: String = #function) {
	#if DEBUG
		let timestamp = ISO8601DateFormatter.string(from: Date(), timeZone: TimeZone.current, formatOptions: [.withYear, .withMonth, .withDay, .withDashSeparatorInDate, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime])
		print("\(timestamp) \(URL(fileURLWithPath: file, isDirectory: false).deletingPathExtension().lastPathComponent): \(function) \(message)")
	#endif
}

@discardableResult
func debugResult<T>(_ result: T, file: String = #file, function: String = #function) -> T {
	debugLog("returned: \(result)", file: file, function: function)
	return result
}