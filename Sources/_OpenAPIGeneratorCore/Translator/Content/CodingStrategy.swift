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

/// Describes the underlying parameter coding strategy.
enum ParameterCodingStrategy: String, Equatable, Hashable, Sendable {

    /// A strategy using JSONEncoder/JSONDecoder.
    case codable

    /// A strategy using LosslessStringConvertible.
    case string

    /// A strategy for letting the type choose the appropriate option.
    case deferredToType

    /// The name of the coding strategy in the runtime library.
    var runtimeName: String {
        switch self {
        case .codable:
            return Constants.CodingStrategy.Parameter.codable
        case .string:
            return Constants.CodingStrategy.Parameter.string
        default:
            return Constants.CodingStrategy.Parameter.deferredToType
        }
    }
}

/// Describes the underlying body coding strategy.
enum BodyCodingStrategy: String, Equatable, Hashable, Sendable {

    /// A strategy using JSONEncoder/JSONDecoder.
    case codable

    /// A strategy using LosslessStringConvertible.
    case string

    /// A strategy passing through the unmodified data.
    case data

    /// The name of the coding strategy in the runtime library.
    var runtimeName: String {
        switch self {
        case .codable:
            return Constants.CodingStrategy.Body.codable
        case .string:
            return Constants.CodingStrategy.Body.string
        case .data:
            return Constants.CodingStrategy.Body.data
        }
    }
}
