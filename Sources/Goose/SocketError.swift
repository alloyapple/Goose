import Glibc

public enum GooseError: Error {

    case message(msg: String)

    public static func error(file: String = #file, line: Int = #line, func: String = #function
    ) -> GooseError {
        let error = String(cString: strerror(errno))
        let msg = "\(file):\(line) \(`func`):\(error)"
        return GooseError.message(msg: msg)
    }
}
