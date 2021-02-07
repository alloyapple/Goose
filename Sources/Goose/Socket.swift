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
}

public enum SocketType: Int32 {
    case tcp = 1
    case udp = 2
}

public enum SocketProtocol: Int32 {
    case tcp = 6
    case udp = 17
    case unix = 0
}

public class Socket {
    public let fd: Int32
    public let family: SockFamily
    public let proto: SocketProtocol
    public let type: SocketType

    public init(family: SockFamily = .inet, type: SocketType = .tcp, proto: SocketProtocol = .tcp) {
        self.fd = Glibc.socket(family.rawValue, type.rawValue, proto.rawValue)
        self.family = family
        self.proto = proto
        self.type = type
    }

    public init(
        fd: Int32, family: SockFamily = .inet, type: SocketType = .tcp, proto: SocketProtocol = .tcp
    ) {
        self.family = family
        self.proto = proto
        self.type = type
        self.fd = fd
    }

    public func accept() throws -> Socket {
        let clientFd = Glibc.accept(fd, nil, nil)
        guard clientFd > 0 else {
            throw SocketError.error()
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
            throw SocketError.error()
        }

        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw SocketError.error()
        }

        res = Glibc.bind(fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
            throw SocketError.error()
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
            throw SocketError.error()
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
            throw SocketError.error()
        }
        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw SocketError.error()
        }

        res = Glibc.connect(self.fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
            throw SocketError.error()
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
            throw SocketError.error()
        }

    }

    public func listen(backlog: Int32 = 4096) throws {
        let res = Glibc.listen(self.fd, backlog)
        guard res == 0 else {
            throw SocketError.error()
        }
    }

    public func write(_ data: [UInt8]) throws -> Int {
        let ret = Glibc.write(self.fd, data, data.count)

        guard ret >= 0 else {
            throw SocketError.error()
        }

        return ret
    }

    public func write(_ data: String) throws -> Int {
        let array: [UInt8] = Array(data.utf8)
        return try write(array)
    }

    public func read(_ data: inout [Int8]) throws -> Int {
        let ret =  Glibc.read(self.fd, &data, data.count)
        guard ret >= 0 else {
            throw SocketError.error()
        }

        return ret
    }

    public func read(max: Int, into buffer: MutableByteBuffer) throws ->  Int {
        let ret = Glibc.read(self.fd, buffer.baseAddress.unsafelyUnwrapped, max)
        guard ret >= 0 else {
            throw SocketError.error()
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
            throw SocketError.error()
        }

        let frame = ByteBuffer(start: pointer, count: read)
        return Data(buffer: frame)
    }

    deinit {
        close(self.fd)
    }
}
