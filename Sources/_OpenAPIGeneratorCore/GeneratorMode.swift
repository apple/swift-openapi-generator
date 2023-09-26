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

/// Describes the file to be generated from the specified OpenAPI document.
public enum GeneratorMode: String, Codable, CaseIterable, Sendable {

    /// A file that contains the API protocol, reusable types, and operation
    /// namespaces.
    ///
    /// This file is used by both the client and server files.
    case types

    /// A file that contains the generated Client structure that implements
    /// the API protocol by calling into a client transport.
    ///
    /// Depends on the types file.
    case client

    /// A file that contains a method that adds the generated server handlers
    /// to the a server transport.
    ///
    /// Depends on the types file.
    case server
}

extension GeneratorMode {

    /// The Swift file name including its file extension.
    public var outputFileName: String {
        switch self {
        case .types:
            return "Types.swift"
        case .client:
            return "Client.swift"
        case .server:
            return "Server.swift"
        }
    }

    /// The Swift file names for all supported generator mode values.
    public static var allOutputFileNames: [String] {
        GeneratorMode.allCases.map(\.outputFileName)
    }

    /// Defines an order in which generators should be run.
    var order: Int {
        switch self {
        case .types:
            return 1
        case .client:
            return 2
        case .server:
            return 3
        }
    }
}

extension GeneratorMode: Comparable {
    public static func < (lhs: GeneratorMode, rhs: GeneratorMode) -> Bool {
        lhs.order < rhs.order
    }
}
