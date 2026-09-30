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

/// A translated component namespace and its output file name.
struct ComponentNamespaceDescription {
    /// The namespace's generated output file.
    var outputFile: OutputFileName

    /// The translated namespace declaration.
    var declaration: Declaration
}

extension TypesFileTranslator {

    /// Returns descriptions of the declarations nested under the components namespace.
    /// - Parameters:
    ///   - components: The components defined in the OpenAPI document.
    ///   - multipartSchemaNames: The names of schemas used as root multipart content.
    /// - Returns: Descriptions representing the second-level component namespaces.
    /// - Throws: An error if there's an issue during translation of components.
    func translateComponentNamespaceDescriptions(
        _ components: OpenAPI.Components,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>
    ) throws -> [ComponentNamespaceDescription] {
        let schemas = try translateSchemas(components.schemas, multipartSchemaNames: multipartSchemaNames)
        let resolvedParameters = try components.parameters.mapValues { try components.assumeLookupOnce($0) }
        let parameters = try translateComponentParameters(resolvedParameters)
        let resolvedRequestBodies = try components.requestBodies.mapValues { try components.assumeLookupOnce($0) }
        let requestBodies = try translateComponentRequestBodies(resolvedRequestBodies)
        let resolvedResponses = try components.responses.mapValues { try components.assumeLookupOnce($0) }
        let responses = try translateComponentResponses(resolvedResponses)
        let resolvedHeaders = try components.headers.mapValues {
            (header: Either<OpenAPI.Reference<OpenAPI.Header>, OpenAPI.Header>) in
            try components.assumeLookupOnce(header)
        }
        let headers = try translateComponentHeaders(resolvedHeaders)

        return [
            .init(outputFile: .typesComponentsSchemas, declaration: schemas),
            .init(outputFile: .typesComponentsParameters, declaration: parameters),
            .init(outputFile: .typesComponentsRequestBodies, declaration: requestBodies),
            .init(outputFile: .typesComponentsResponses, declaration: responses),
            .init(outputFile: .typesComponentsHeaders, declaration: headers),
        ]
    }
}
