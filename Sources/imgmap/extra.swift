import Foundation
import ArgumentParser
import RenderKit

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        let path: String = argument.replacingOccurrences(of: "\\ ", with: " ")
        if path.starts(with: "/") {
            self = URL(fileURLWithPath: path)
        } else if path.starts(with: "~/") {
            self = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(path.replacingOccurrences(of: "~/", with: ""))
        } else {
            let callURL: URL = URL(fileURLWithPath: CommandLine.arguments.first!).deletingLastPathComponent()
            if argument == "." {
                self = callURL
            } else {
                self = callURL.appendingPathComponent(path)
            }
        }
    }
}

extension Resolution: ExpressibleByArgument {
    public init?(argument: String) {
        if argument.contains("x") {
            let parts: [String] = argument.split(separator: "x").map({"\($0)"})
            let widthStr: String = parts[0]
            let heightStr: String = parts[1]
            guard let width: Int = Int(widthStr),
                  let height: Int = Int(heightStr) else {
                return nil
            }
            self = .custom(w: width, h: height)
        } else if let val = Int(argument) {
            self = .square(val)
        } else if let res: Resolution = Resolution.standardCases.first(where: { $0.name == argument }) {
            self = res
        } else {
            return nil
        }
    }
}

extension Placement: ExpressibleByArgument {
    public init?(argument: String) {
        guard let placement: Placement = Placement(rawValue: argument) else { return nil }
        self = placement
    }
}
