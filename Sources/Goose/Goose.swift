import Foundation
import Glibc

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

public extension UnsafeRawPointer {
    func unretainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeUnretainedValue()
    }

    func retainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeRetainedValue()
    }
}

public extension UnsafeMutableRawPointer {
    func unretainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeUnretainedValue()
    }

    func retainedValue<T: AnyObject>() -> T {
        return Unmanaged<T>.fromOpaque(self).takeRetainedValue()
    }
}
