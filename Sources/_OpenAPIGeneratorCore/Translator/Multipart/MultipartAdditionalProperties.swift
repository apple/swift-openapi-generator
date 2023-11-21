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

enum MultipartAdditionalPropertiesStrategy {
    case disallowed
    case allowed
    case typed(JSONSchema)
    case any
}

extension FileTranslator {
    
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
    
    func translateMultipartAdditionalPropertiesCase(_ strategy: MultipartAdditionalPropertiesStrategy) -> [Declaration] {
        switch strategy {
        case .disallowed:
            return []
        case .allowed:
            return [
                .enumCase(name: "undocumented", kind: .nameWithAssociatedValues([
                    .init(type: .init(.multipartRawPart))
                ]))
            ]
        case .typed(let schema):
            // TODO:
            fatalError()
        case .any:
            return [
                .enumCase(name: "other", kind: .nameWithAssociatedValues([
                    .init(type: .init(.multipartRawPart))
                ]))
            ]
        }
    }
}
