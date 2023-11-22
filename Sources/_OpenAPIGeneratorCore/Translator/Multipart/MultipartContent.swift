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

struct MultipartContent {
    var typeName: TypeName
    var parts: [MultipartSchemaTypedContent]
    var additionalPropertiesStrategy: MultipartAdditionalPropertiesStrategy
    var requirements: MultipartRequirements
}

enum MultipartSchemaTypedContent {
    struct DocumentedTypeInfo {
        var originalName: String
        var typeName: TypeName
        var partInfo: MultipartPartInfo
        var schema: JSONSchema
        var headers: OpenAPI.Header.Map?
    }
    case documentedTyped(DocumentedTypeInfo)
    
    struct OtherDynamicallyNamedInfo {
        var typeName: TypeName
        var partInfo: MultipartPartInfo
        var schema: JSONSchema
    }
    case otherDynamicallyNamed(OtherDynamicallyNamedInfo)
    
    case otherRaw
    case undocumented
}

extension MultipartSchemaTypedContent {
    
    var innerTypeName: TypeName? {
        switch self {
        case .documentedTyped(let info):
            return info.typeName
        case .otherDynamicallyNamed(let info):
            return info.typeName
        default:
            return nil
        }
    }
    
    var wrapperTypeUsage: TypeUsage {
        switch self {
        case .documentedTyped(let info):
            return info.typeName.asUsage.asWrapped(in: .multipartPart)
        case .otherDynamicallyNamed(let info):
            return info.typeName.asUsage.asWrapped(in: .multipartDynamicallyNamedPart)
        case .otherRaw, .undocumented:
            return TypeName.multipartRawPart.asUsage
        }
    }
}
