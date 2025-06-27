//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation

func resolveExecutable(_ name: String) throws -> URL {
    struct Static {
        #if os(Windows)
        static let separator = ";"
        static let suffix = ".exe"
        #else
        static let separator = ":"
        static let suffix = ""
        #endif
    }

    enum PathResolutionError: Error, CustomStringConvertible {
        case notFound(name: String, path: String)
        var description: String {
            switch self {
            case let .notFound(name, path): "Could not find \(name)\(Static.suffix) in PATH: \(path)"
            }
        }
    }
    let env = Dictionary(
        uniqueKeysWithValues: ProcessInfo.processInfo.environment.map { (k, v) in
            #if os(Windows)
            return (k.uppercased(), v)
            #else
            return (k, v)
            #endif
        }
    )
    let paths = (env["PATH"] ?? "").split(separator: Static.separator).map(String.init)
    for path in paths {
        let fullPath = path + "/" + name + Static.suffix
        if FileManager.default.fileExists(atPath: fullPath) { return URL(fileURLWithPath: fullPath) }
    }
    throw PathResolutionError.notFound(name: name, path: env["PATH"] ?? "")
}
