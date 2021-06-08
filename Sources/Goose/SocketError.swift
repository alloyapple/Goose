import Glibc



protocol BaseGooseError: Error {
    var msg: String { get  }
    init(msg: String)

    static func error(
        file: String, line: Int, func: String
    ) -> Self

}

extension BaseGooseError {
    public static func error(
        file: String = #file, line: Int = #line, func: String = #function
    ) -> Self {
        let error = String(cString: strerror(errno))
        let msg = "\(file):\(line) \(`func`):\(error)"
        return Self(msg: msg)
    }
}

public enum GooseError: Error {

    case message(msg: String)

    public static func error(
        file: String = #file, line: Int = #line, func: String = #function
    ) -> GooseError {
        let error = String(cString: strerror(errno))
        let msg = "\(file):\(line) \(`func`):\(error)"
        return GooseError.message(msg: msg)
    }
}

public struct BindError: BaseGooseError {
    var msg: String
    init(msg: String) {
        self.msg = msg
    }
}
