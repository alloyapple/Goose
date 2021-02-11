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

class Foo {
    public func clicked(_ f:()->()) {
        let cfunc: @convention(c) (Int, Int) -> Int = { (a, b) in
            return 2
        }
        typealias cfunctype =  @convention(c) () -> ()
        let cfunc1: cfunctype = unsafeBitCast(cfunc, to: cfunctype.self )


    }

    public func abc() {
        
    }

    public func abc1() -> Int {
        self.clicked(self.abc)
        return 3
    }
}

func test() {
    let foo = Foo()
    foo.clicked { 
    }
}