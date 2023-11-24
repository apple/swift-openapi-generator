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

/// Describes the underlying coding strategy.
enum CodingStrategy: String, Hashable, Sendable {

    /// A strategy using JSONEncoder/JSONDecoder.
    case json

    /// A strategy using URIEncoder/URIDecoder.
    case uri

    /// A strategy that passes through the data unmodified.
    case binary

    /// A strategy using x-www-form-urlencoded.
    case urlEncodedForm

    /// A strategy using multipart/form-data.
    case multipart

    /// The name of the coding strategy in the runtime library.
    var runtimeName: String {
        switch self {
        case .json: return Constants.CodingStrategy.json
        case .uri: return Constants.CodingStrategy.uri
        case .binary: return Constants.CodingStrategy.binary
        case .urlEncodedForm: return Constants.CodingStrategy.urlEncodedForm
        case .multipart: return Constants.CodingStrategy.multipart
        }
    }
}
