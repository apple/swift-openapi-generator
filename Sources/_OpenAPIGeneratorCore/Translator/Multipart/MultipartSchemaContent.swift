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

struct MultipartSchemaTypedContent {

    var originalName: String
    
    enum CaseKind {
        case documentedTyped(TypeName)
        case otherDynamicallyNamed(TypeName)
        case otherRaw
        case undocumented
    }
    var caseKind: CaseKind
    
    var contentType: ContentType
    
    var schema: JSONSchema
    
    var headers: OpenAPI.Header.Map?
}

extension MultipartSchemaTypedContent {
    
    var innerTypeName: TypeName? {
        switch caseKind {
        case .documentedTyped(let typeName), .otherDynamicallyNamed(let typeName):
            return typeName
        default:
            return nil
        }
    }
    
    var wrapperTypeUsage: TypeUsage {
        switch caseKind {
        case .documentedTyped(let innerTypeName):
            return innerTypeName.asUsage.asWrapped(in: .multipartPart)
        case .otherDynamicallyNamed(let innerTypeName):
            return innerTypeName.asUsage.asWrapped(in: .multipartDynamicallyNamedPart)
        case .otherRaw, .undocumented:
            return TypeName.multipartRawPart.asUsage
        }
    }
}
