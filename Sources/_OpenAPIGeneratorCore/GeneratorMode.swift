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
    public var outputFileName: OutputFileName {
        switch self {
        case .types: return .types
        case .client: return .client
        case .server: return .server
        }
    }

    /// The Swift file names emitted for this generator mode.
    public var outputFileNames: Set<OutputFileName> {
        switch self {
        case .types:
            return [
                .types, .typesComponents, .typesOperations, .typesComponentsSchemas, .typesComponentsParameters,
                .typesComponentsRequestBodies, .typesComponentsResponses, .typesComponentsHeaders,
            ]
        case .client: return [.client]
        case .server: return [.server]
        }
    }

    /// The Swift file names for all supported generator mode values.
    public static var allOutputFileNames: Set<OutputFileName> { Set(OutputFileName.allCases) }

    /// Defines an order in which generators should be run.
    var order: Int {
        switch self {
        case .types: return 1
        case .client: return 2
        case .server: return 3
        }
    }
}

extension GeneratorMode: Comparable {
    /// Compares modes based on their order.
    public static func < (lhs: GeneratorMode, rhs: GeneratorMode) -> Bool { lhs.order < rhs.order }
}

/// The name of a Swift file emitted by the generator.
public enum OutputFileName: String, Hashable, CaseIterable, Sendable {

    /// The generated root types file.
    case types = "Types.swift"

    /// The generated components namespace file.
    case typesComponents = "Types+Components.swift"

    /// The generated operations namespace file.
    case typesOperations = "Types+Operations.swift"

    /// The generated component schemas namespace file.
    case typesComponentsSchemas = "Types+Components+Schemas.swift"

    /// The generated component parameters namespace file.
    case typesComponentsParameters = "Types+Components+Parameters.swift"

    /// The generated component request bodies namespace file.
    case typesComponentsRequestBodies = "Types+Components+RequestBodies.swift"

    /// The generated component responses namespace file.
    case typesComponentsResponses = "Types+Components+Responses.swift"

    /// The generated component headers namespace file.
    case typesComponentsHeaders = "Types+Components+Headers.swift"

    /// The generated client file.
    case client = "Client.swift"

    /// The generated server file.
    case server = "Server.swift"
}
