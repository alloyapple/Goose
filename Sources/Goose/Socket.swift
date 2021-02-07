import Glibc

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

    public init(fd: Int32, family: SockFamily = .inet, type: SocketType = .tcp, proto: SocketProtocol = .tcp) {
        self.family = family
        self.proto = proto
        self.type = type
        self.fd = fd
    }

    public func accept() throws ->  Socket {
        let clientFd = Glibc.accept(fd, nil, nil)
        guard clientFd > 0 else {
            throw SocketError.error(errnum: clientFd)
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
            throw SocketError.error(errnum: res)
        }

        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw SocketError.error(errnum: res)
        }

        res = Glibc.bind(fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
            throw SocketError.error(errnum: res)
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
            throw SocketError.error(errnum: ret)
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
            throw SocketError.error(errnum: res)
        }
        defer {
            freeaddrinfo(result)
        }

        guard let info = result else {
            throw SocketError.error(errnum: res)
        }

        res = Glibc.connect(self.fd, info.pointee.ai_addr, info.pointee.ai_addrlen)
        guard res == 0 else {
           throw SocketError.error(errnum: res)
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
            Glibc.connect(fd, UnsafeMutableRawPointer($0).assumingMemoryBound(to: sockaddr.self), UInt32(addrlen))

        }

        guard ret > 0 else {
            throw SocketError.error(errnum: ret)
        }

        
    }

    public func listen(backlog: Int32 = 4096) throws {
        let res = Glibc.listen(self.fd, backlog)
        guard res == 0 else {
            throw SocketError.error(errnum: res)
        }
    }

    deinit {
        close(self.fd)
    }
}
