import Glibc


public struct GooseError: Error {
    let name: String
    let msg: String
    let code: Int32

    public static func error(
        file: String = #file, line: Int = #line, func: String = #function, name: String = #function, code: Int32 = errno
    ) -> GooseError {
        let error = String(cString: strerror(errno))
        let msg = "\(file):\(line) \(`func`):\(error)"
        return GooseError(name: name,  msg: msg, code:code)
    }
}

