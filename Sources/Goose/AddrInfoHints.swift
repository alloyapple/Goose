import Glibc


public func getaddrinfo(
    host: String, port: UInt16, family: SockFamily = SockFamily.inet,
    type: SocketType = SocketType.tcp, proto: SocketProtocol = SocketProtocol.tcp, flags: Int32 = 0
) throws -> UnsafeMutablePointer<addrinfo>? {
    var hints = addrinfo()
    // Support both IPv4 and IPv6
    hints.ai_family = family.rawValue
    hints.ai_socktype = type.rawValue
    hints.ai_flags = flags
    hints.ai_protocol = proto.rawValue
    var result: UnsafeMutablePointer<addrinfo>?

    let res = getaddrinfo(host, "\(port)", &hints, &result)
    guard res >= 0 else {
        throw SocketError.error()
    }

    guard res >= 0 else {
        throw SocketError.error()
    }

    return result
}
