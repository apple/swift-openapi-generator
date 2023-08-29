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

extension TypesFileTranslator {

    /// Returns a declaration of a code block containing the components
    /// namespace, which contains all the reusable component namespaces, such
    /// as for schemas, parameters, and response headers.
    /// - Parameter components: The components defined in the OpenAPI document.
    /// - Returns: A code block with the enum representing the components
    /// namespace.
    func translateComponents(
        _ components: OpenAPI.Components
    ) throws -> CodeBlock {

        let schemas = try translateSchemas(components.schemas)
        let parameters = try translateComponentParameters(components.parameters)
        let requestBodies = try translateComponentRequestBodies(components.requestBodies)
        let responses = try translateComponentResponses(components.responses)
        let headers = try translateComponentHeaders(components.headers)

        let componentsDecl: Declaration = .commentable(
            .doc(
                """
                Types generated from the components section of the OpenAPI document.
                """
            ),
            .enum(
                .init(
                    accessModifier: config.access,
                    name: "Components",
                    members: [
                        schemas,
                        parameters,
                        requestBodies,
                        responses,
                        headers,
                    ]
                )
            )
        )
        return .declaration(componentsDecl)
    }
}
