import Foundation
import Glibc

public typealias Byte = UInt8
public typealias Bytes = [Byte]
public typealias ByteBuffer = UnsafeBufferPointer<Byte>
public typealias MutableByteBuffer = UnsafeMutableBufferPointer<Byte>
public typealias BytesPointer = UnsafePointer<Byte>
public typealias MutableBytesPointer = UnsafeMutablePointer<Byte>

public enum SockFamily: Int32 {
    case inet = 2
    case inet6 = 10
    case unix = 1

    public init(fromRawValue: Int32) {
        self = SockFamily(rawValue: fromRawValue) ?? .inet
    }
}

public enum SockType: Int32 {
    case tcp = 1
    case udp = 2

    public init(fromRawValue: Int32) {
        self = SockType(rawValue: fromRawValue) ?? .tcp
    }
}

public enum SockProt: Int32 {
    case tcp = 6
    case udp = 17
    case unix = 0

    public init(fromRawValue: Int32) {
        self = SockProt(rawValue: fromRawValue) ?? .tcp
    }
}

public class Socket {
    public let fd: Int32
    public let family: SockFamily
    public let proto: SockProt
    public let type: SockType

    public init(family: SockFamily = .inet, type: SockType = .tcp, proto: SockProt = .tcp) {
        self.fd = Glibc.socket(family.rawValue, type.rawValue, proto.rawValue)
        self.family = family
        self.proto = proto
        self.type = type
    }

    public init(
        fd: Int32, family: SockFamily = .inet, type: SockType = .tcp, proto: SockProt = .tcp
    ) {
        self.family = family
        self.proto = proto
        self.type = type
        self.fd = fd
    }

    public func accept() throws -> Socket {
        let clientFd = Glibc.accept(fd, nil, nil)
        guard clientFd > 0 else {
            throw GooseError.error()
        }

        return Socket(fd: clientFd, family: self.family, type: self.type, proto: self.proto)
    }

    public func bind(hostname: String? = "localhost", port: UInt16 = 80) throws {
        var hints = addrinfo()

        // Support both IPv4 and IPv6
        hints.ai_family = self.family.rawValue

        // Specify that this is a TCP Stream
        hints.ai_socktype = self.type.rawValue
        hints.ai_protocol = self.proto.rawValue

        // If the AI_PASSIVE flag is specified in hints.ai_flags, and node is
        // NULL, then the returned socket addresses will be suitable for
        // bind(2)ing a socket that will accept(2) connections.
        hints.ai_flags = AI_PASSIVE

        // Look ip the sockeaddr for the hostname
        var result: UnsafeMutablePointer<addrinfo>?

        var res = Glibc.getaddrinfo(hostname, "\(port)", &hints, &result)
        guard res == 0 else {
            throw GooseError.error()
        }

        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw GooseError.error()
        }

        res = Glibc.bind(fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
            throw GooseError.error()
        }
    }

    public func bind(path: String) throws {
        _ = Glibc.unlink(path)

        let addrlen = MemoryLayout<sockaddr_un>.size
        var acceptAddr = sockaddr_un()
        acceptAddr.sun_family = UInt16(Glibc.AF_UNIX)

        let bytes = path.utf8CString
        var buffer = [CChar](repeating: 0, count: MemoryLayout.size(ofValue: acceptAddr.sun_path))
        for (i, byte) in bytes.enumerated() {
            buffer[i] = CChar(byte)
            if i >= path.count - 1 {
                break
            }
        }

        memcpy(&acceptAddr.sun_path.0, &buffer[0], buffer.count - 1)

        let ret = Glibc.bind(self.fd, toAddr(&acceptAddr), UInt32(addrlen))

        guard ret > 0 else {
            throw GooseError.error()
        }
    }

    public func connect(hostname: String = "localhost", port: UInt16 = 80) throws {
        var hints = addrinfo()

        // Support both IPv4 and IPv6
        hints.ai_family = self.family.rawValue

        // Specify that this is a TCP Stream
        hints.ai_socktype = self.type.rawValue

        // Look ip the sockeaddr for the hostname
        var result: UnsafeMutablePointer<addrinfo>?

        var res = getaddrinfo(hostname, "\(port)", &hints, &result)
        guard res == 0 else {
            throw GooseError.error()
        }
        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw GooseError.error()
        }

        res = Glibc.connect(self.fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
            throw GooseError.error()
        }

    }

    public func connect(addr: UnsafeMutablePointer<addrinfo>) throws {
        let ret = Glibc.connect(
            fd, addr.pointee.ai_addr,
            addr.pointee.ai_addrlen)

        guard ret > 0 else {
            throw GooseError.error()
        }

    }

    public func connect(path: String) throws {
        _ = Glibc.unlink(path)

        let addrlen = MemoryLayout<sockaddr_un>.size
        var acceptAddr = sockaddr_un()
        acceptAddr.sun_family = UInt16(Glibc.AF_UNIX)

        let bytes = path.utf8CString

        var buffer = [CChar](repeating: 0, count: MemoryLayout.size(ofValue: acceptAddr.sun_path))
        for (i, byte) in bytes.enumerated() {
            buffer[i] = CChar(byte)
            if i >= path.count - 1 {
                break
            }
        }

        memcpy(&acceptAddr.sun_path.0, &buffer[0], buffer.count - 1)

        let ret = withUnsafeMutablePointer(to: &acceptAddr) {
            Glibc.connect(
                fd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self),
                UInt32(addrlen))

        }

        guard ret > 0 else {
            throw GooseError.error()
        }

    }

    public func listen(backlog: Int32 = 4096) throws {
        let res = Glibc.listen(self.fd, backlog)
        guard res == 0 else {
            throw GooseError.error()
        }
    }

    public func write(_ data: [UInt8]) throws -> Int {
        let ret = Glibc.write(self.fd, data, data.count)

        guard ret >= 0 else {
            throw GooseError.error()
        }

        return ret
    }

    public func write(_ data: String) throws -> Int {
        let array: [UInt8] = Array(data.utf8)
        return try write(array)
    }

    public func read(_ data: inout [Int8]) throws -> Int {
        let ret = Glibc.read(self.fd, &data, data.count)
        guard ret >= 0 else {
            throw GooseError.error()
        }

        return ret
    }

    public func read(max: Int, into buffer: MutableByteBuffer) throws -> Int {
        let ret = Glibc.read(self.fd, buffer.baseAddress.unsafelyUnwrapped, max)
        guard ret >= 0 else {
            throw GooseError.error()
        }

        return ret

    }

    public func read(_ max: Int) throws -> Data {
        let pointer = MutableBytesPointer.allocate(capacity: max)
        defer {
            pointer.deallocate()
            pointer.deinitialize(count: max)
        }
        let buffer = MutableByteBuffer(start: pointer, count: max)
        let read = try self.read(max: max, into: buffer)

        guard read >= 0 else {
            throw GooseError.error()
        }

        let frame = ByteBuffer(start: pointer, count: read)
        return Data(buffer: frame)
    }

    fileprivate func sockoptsize(_ level: Int32, _ name: Int32) -> Int {
        var length = socklen_t(256)
        var buffer = [UInt8](repeating: 0, count: Int(length))
        return buffer.withUnsafeMutableBufferPointer {
            (buffer: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            let result = Glibc.getsockopt(self.fd, level, name, buffer.baseAddress, &length)
            if result != 0 {
                return 0
            }
            return Int(length)
        }
    }

    public func getsockopt<T>(level: Int, name: Int32) -> T? {

        guard sockoptsize(Int32(level), name) == MemoryLayout<T>.size else {
            return nil
        }

        let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
        defer {
            ptr.deallocate()
        }
        var length = socklen_t(MemoryLayout<T>.size)
        let result = Glibc.getsockopt(self.fd, Int32(level), name, ptr, &length)
        if result != 0 {
            return nil
        }
        let value = ptr.pointee
        return value
    }

    @discardableResult
    public func setsockopt<T>(level: Int, name: Int32, value: T) -> Bool {
        guard sockoptsize(Int32(level), name) == MemoryLayout<T>.size else {
            return false
        }

        var value = value
        let result = Glibc.setsockopt(
            self.fd, Int32(level), name, &value, socklen_t(MemoryLayout<T>.size))
        if result != 0 {
            return false
        }

        return true
    }

    public func getsockopt(level: Int, name: Int32) -> Bool {
        let value: Int32 = getsockopt(level: level, name: name) ?? -1
        return value != 0
    }

    public func setsockopt(level: Int, name: Int32, value: Bool) {
        let value: Int32 = value ? -1 : 0
        setsockopt(level: level, name: name, value: value)
    }

    deinit {
        close(self.fd)
    }
}

extension Socket {

    public var options: SocketOptions {
        return SocketOptions(socket: self)
    }

}

public class SocketOptions {

    public fileprivate(set) weak var socket: Socket?

    public init(socket: Socket) {
        self.socket = socket
    }

}

extension SocketOptions {
    var reuseAddress: Bool {
        get {
            return socket?.getsockopt(level: Int(SOL_SOCKET), name: SO_REUSEADDR) ?? false
        }
        set {
            socket?.setsockopt(level: Int(SOL_SOCKET), name: SO_REUSEADDR, value: newValue)
        }
    }

}
