import Glibc

public struct AddrInfoIterator: IteratorProtocol {
    var addrinfo: UnsafeMutablePointer<addrinfo>?

    init(_ addrinfo: UnsafeMutablePointer<addrinfo>?) {
        self.addrinfo = addrinfo
    }

    public mutating func next() -> UnsafeMutablePointer<addrinfo>? {
        let addr = addrinfo
        addrinfo = addrinfo?.pointee.ai_next
        return addr
    }
}
public class AddrInfo: Sequence {
    let addr: UnsafeMutablePointer<addrinfo>?

    public init(_ addr: UnsafeMutablePointer<addrinfo>?) {
        self.addr = addr
    }

    public func makeIterator() -> AddrInfoIterator {
        return AddrInfoIterator(self.addr)
    }

    deinit {
        freeaddrinfo(addr)
    }

}

public func getAddrinfo(
    host: String, port: UInt16, family: SockFamily = SockFamily.inet,
    type: SockType = SockType.tcp, proto: SockProt = SockProt.tcp, flags: Int32 = 0
) throws -> AddrInfo {
    var hints = addrinfo()
    // Support both IPv4 and IPv6
    hints.ai_family = family.rawValue
    hints.ai_socktype = type.rawValue
    hints.ai_flags = flags
    hints.ai_protocol = proto.rawValue
    var result: UnsafeMutablePointer<addrinfo>?

    let res = getaddrinfo(host, "\(port)", &hints, &result)
    guard res >= 0 else {
        throw GooseError.error()
    }

    guard res >= 0 else {
        throw GooseError.error()
    }

    return AddrInfo(result)
}

extension addrinfo {
    public var family: SockFamily {
        return SockFamily(fromRawValue: self.ai_family)
    }

    public var type: SockType {
        return SockType(fromRawValue: self.ai_socktype)
    }

    public var prot: SockProt {
        return SockProt(fromRawValue: self.ai_protocol)
    }

    public var flags: Int32 {
        return self.ai_flags
    }
}
