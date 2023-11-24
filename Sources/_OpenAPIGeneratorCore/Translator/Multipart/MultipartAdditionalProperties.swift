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
import OpenAPIKit

/// The strategy for handling the additional properties key in a multipart schema.
enum MultipartAdditionalPropertiesStrategy: Equatable {

    /// A strategy where additional properties are explicitly disallowed.
    case disallowed

    /// A strategy where additional properties are implicitly allowed.
    case allowed

    /// A strategy where all additional properties must conform to the given schema.
    case typed(JSONSchema)

    /// A strategy where additional properties are explicitly allowed, and are freeform.
    case any
}

extension FileTranslator {
    
    /// Computes the additional properties strategy given the schema's additional properties value.
    /// - Parameter additionalProperties: The schema's additional properties value.
    /// - Returns: The computed strategy.
    func parseMultipartAdditionalPropertiesStrategy(_ additionalProperties: Either<Bool, JSONSchema>?) -> MultipartAdditionalPropertiesStrategy {
        switch additionalProperties {
        case .none:
            return .allowed
        case .a(let bool):
            return bool ? .any : .disallowed
        case .b(let schema):
            return .typed(schema)
        }
    }
}
