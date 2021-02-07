public struct AddrInfoHints {
    let socktype: SocketType
    let `protocol`: SocketProtocol
    let address: Int32
    let flags: Int32
}

public func getaddrinfo(host: String, service: Int, hints: AddrInfoHints) throws -> [AddrInfoHints] {
    return []
}