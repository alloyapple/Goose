import Glibc

public enum SocketError: Error {

    case message(msg: String)

    public static func error(
        errnum: Int32, file: String = #file, line: Int = #line, func: String = #function
    ) -> SocketError {
        let error = String(cString: strerror(errnum))
        let msg = "\(file):\(line) \(`func`):\(error)"
        return SocketError.message(msg: msg)
    }
}
