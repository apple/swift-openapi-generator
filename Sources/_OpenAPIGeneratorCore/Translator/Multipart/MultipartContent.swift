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

/// The top level container of multipart parts.
struct MultipartContent {

    /// The type name of the enclosing enum.
    var typeName: TypeName

    /// The multipart parts.
    var parts: [MultipartSchemaTypedContent]

    /// The strategy for handling additional properties.
    var additionalPropertiesStrategy: MultipartAdditionalPropertiesStrategy

    /// The requirements enforced by the validation sequence.
    var requirements: MultipartRequirements
}

/// A container of information about an individual multipart part.
enum MultipartSchemaTypedContent {

    /// The associated data with the `documentedTyped` case.
    struct DocumentedTypeInfo {

        /// The original name of the case from the OpenAPI document.
        var originalName: String

        /// The type name of the part wrapper.
        var typeName: TypeName

        /// Information about the kind of the part.
        var partInfo: MultipartPartInfo

        /// The value schema of the part defined in the OpenAPI document.
        var schema: JSONSchema

        /// The headers defined for the part in the OpenAPI document.
        var headers: OpenAPI.Header.Map?
    }
    /// A documented part with a name specified in the OpenAPI document.
    case documentedTyped(DocumentedTypeInfo)

    /// The associated data with the `otherDynamicallyNamed` case.
    struct OtherDynamicallyNamedInfo {

        /// The type name of the part wrapper.
        var typeName: TypeName

        /// Information about the kind of the part.
        var partInfo: MultipartPartInfo

        /// The value schema of the part defined in the OpenAPI document.
        var schema: JSONSchema
    }
    /// A part representing additional properties with a schema constraint.
    case otherDynamicallyNamed(OtherDynamicallyNamedInfo)

    /// A part representing explicitly allowed, freeform additional properties.
    case otherRaw

    /// A part representing an undocumented value.
    case undocumented
}

extension MultipartSchemaTypedContent {

    /// The type usage of the part type wrapper.
    ///
    /// For example, for a documented part, the generated type is wrapped in `OpenAPIRuntime.MultipartPart<...>`.
    var wrapperTypeUsage: TypeUsage {
        switch self {
        case .documentedTyped(let info): return info.typeName.asUsage.asWrapped(in: .multipartPart)
        case .otherDynamicallyNamed(let info):
            return info.typeName.asUsage.asWrapped(in: .multipartDynamicallyNamedPart)
        case .otherRaw, .undocumented: return TypeName.multipartRawPart.asUsage
        }
    }
}

extension TypeMatcher {
    /// Returns a Boolean value whether the schema is a multipart content type and is referenceable.
    func isReferenceableMultipart(_ content: SchemaContent) -> Bool {
        guard content.contentType.isMultipart else { return false }
        let ref = multipartElementTypeReferenceIfReferenceable(schema: content.schema, encoding: content.encoding)
        return ref == nil
    }
}
