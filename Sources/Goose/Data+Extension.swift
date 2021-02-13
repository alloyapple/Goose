import Foundation
import Glibc

extension Data {
    public func readLine() -> [UInt8]? {
        var data = [UInt8](self)
        guard let e = memchr(&data, 10, data.count) else {
            return nil
        }

        let distance = abs(e.distance(to: &data))
        return Array(data[...distance])
    }

    public func readLines() -> [[UInt8]] {
        var list: [[UInt8]] = []
        var data = [UInt8](self)

        while true {
            guard let e = memchr(&data, 10, data.count) else {
                break
            }

            let distance = abs(e.distance(to: &data))
            list.append(Array(data[...distance]))
            data = Array(data.dropFirst(distance + 1))
        }

        return list
    }
}
