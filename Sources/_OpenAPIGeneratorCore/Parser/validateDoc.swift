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

/// Validates all content types from an OpenAPI document represented by a ParsedOpenAPIRepresentation.
///
/// This function iterates through the paths, endpoints, and components of the OpenAPI document,
/// checking and reporting any invalid content types using the provided validation closure.
///
/// - Parameters:
///   - doc: The OpenAPI document representation.
///   - validate: A closure to validate each content type.
/// - Throws: An error with diagnostic information if any invalid content types are found.
func validateContentTypes(in doc: ParsedOpenAPIRepresentation, validate: (String) -> Bool) throws {
    for (path, pathValue) in doc.paths {
        guard let pathItem = pathValue.pathItemValue else { continue }
        for endpoint in pathItem.endpoints {

            if let eitherRequest = endpoint.operation.requestBody {
                if let actualRequest = eitherRequest.requestValue {
                    for contentType in actualRequest.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message: "Invalid content type string.",
                                context: [
                                    "contentType": contentType.rawValue,
                                    "location": "\(path.rawValue)/\(endpoint.method.rawValue)/requestBody",
                                    "recoverySuggestion":
                                        "Must have 2 components separated by a slash '<type>/<subtype>'.",
                                ]
                            )
                        }
                    }
                }
            }

            for eitherResponse in endpoint.operation.responses.values {
                if let actualResponse = eitherResponse.responseValue {
                    for contentType in actualResponse.content.keys {
                        if !validate(contentType.rawValue) {
                            throw Diagnostic.error(
                                message: "Invalid content type string.",
                                context: [
                                    "contentType": contentType.rawValue,
                                    "location": "\(path.rawValue)/\(endpoint.method.rawValue)/responses",
                                    "recoverySuggestion":
                                        "Must have 2 components separated by a slash '<type>/<subtype>'.",
                                ]
                            )
                        }
                    }
                }
            }
        }
    }

    for (key, component) in doc.components.requestBodies {
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message: "Invalid content type string.",
                    context: [
                        "contentType": contentType.rawValue, "location": "#/components/requestBodies/\(key.rawValue)",
                        "recoverySuggestion": "Must have 2 components separated by a slash '<type>/<subtype>'.",
                    ]
                )
            }
        }
    }

    for (key, component) in doc.components.responses {
        for contentType in component.content.keys {
            if !validate(contentType.rawValue) {
                throw Diagnostic.error(
                    message: "Invalid content type string.",
                    context: [
                        "contentType": contentType.rawValue, "location": "#/components/responses/\(key.rawValue)",
                        "recoverySuggestion": "Must have 2 components separated by a slash '<type>/<subtype>'.",
                    ]
                )
            }
        }
    }
}

/// Validates all references from an OpenAPI document represented by a ParsedOpenAPIRepresentation against its components.
///
/// This method traverses the OpenAPI document to ensure that all references
/// within the document are valid and point to existing components.
///
/// - Parameter doc: The OpenAPI document to validate.
/// - Throws: `Diagnostic.error` if an external reference is found or a reference is not found in components.
func validateReferences(in doc: ParsedOpenAPIRepresentation) throws {
    func validateReference<ReferenceType: ComponentDictionaryLocatable>(
        _ reference: OpenAPI.Reference<ReferenceType>,
        in components: OpenAPI.Components,
        location: String
    ) throws {
        if reference.isExternal {
            throw Diagnostic.error(
                message: "External references are not suppported.",
                context: ["reference": reference.absoluteString, "location": location]
            )
        }
        if components[reference] == nil {
            throw Diagnostic.error(
                message: "Reference not found in components.",
                context: ["reference": reference.absoluteString, "location": location]
            )
        }
    }

    func validateReferencesInContentTypes(_ content: OpenAPI.Content.Map, location: String) throws {
        for (contentKey, contentType) in content {
            if let reference = contentType.schema?.reference {
                try validateReference(
                    reference,
                    in: doc.components,
                    location: location + "/content/\(contentKey.rawValue)/schema"
                )
            }
            if let eitherExamples = contentType.examples?.values {
                for example in eitherExamples {
                    if let reference = example.reference {
                        try validateReference(
                            reference,
                            in: doc.components,
                            location: location + "/content/\(contentKey.rawValue)/examples"
                        )
                    }
                }
            }
        }
    }

    for (key, value) in doc.webhooks {
        if let reference = value.reference { try validateReference(reference, in: doc.components, location: key) }
    }

    for (path, pathValue) in doc.paths {
        if let reference = pathValue.reference {
            try validateReference(reference, in: doc.components, location: path.rawValue)
        } else if let pathItem = pathValue.pathItemValue {

            for endpoint in pathItem.endpoints {
                for (endpointKey, endpointValue) in endpoint.operation.callbacks {
                    if let reference = endpointValue.reference {
                        try validateReference(
                            reference,
                            in: doc.components,
                            location: "\(path.rawValue)/\(endpoint.method.rawValue)/callbacks/\(endpointKey)"
                        )
                    }
                }

                for eitherParameter in endpoint.operation.parameters {
                    if let reference = eitherParameter.reference {
                        try validateReference(
                            reference,
                            in: doc.components,
                            location: "\(path.rawValue)/\(endpoint.method.rawValue)/parameters"
                        )
                    } else if let parameter = eitherParameter.parameterValue {
                        if let reference = parameter.schemaOrContent.schemaReference {
                            try validateReference(
                                reference,
                                in: doc.components,
                                location: "\(path.rawValue)/\(endpoint.method.rawValue)/parameters/\(parameter.name)"
                            )
                        } else if let content = parameter.schemaOrContent.contentValue {
                            try validateReferencesInContentTypes(
                                content,
                                location: "\(path.rawValue)/\(endpoint.method.rawValue)/parameters/\(parameter.name)"
                            )
                        }
                    }
                }
                if let reference = endpoint.operation.requestBody?.reference {
                    try validateReference(
                        reference,
                        in: doc.components,
                        location: "\(path.rawValue)/\(endpoint.method.rawValue)/requestBody"
                    )
                } else if let requestBodyValue = endpoint.operation.requestBody?.requestValue {
                    try validateReferencesInContentTypes(
                        requestBodyValue.content,
                        location: "\(path.rawValue)/\(endpoint.method.rawValue)/requestBody"
                    )
                }

                for (statusCode, eitherResponse) in endpoint.operation.responses {
                    if let reference = eitherResponse.reference {
                        try validateReference(
                            reference,
                            in: doc.components,
                            location: "\(path.rawValue)/\(endpoint.method.rawValue)/responses/\(statusCode.rawValue)"
                        )
                    } else if let responseValue = eitherResponse.responseValue {
                        try validateReferencesInContentTypes(
                            responseValue.content,
                            location: "\(path.rawValue)/\(endpoint.method.rawValue)/responses/\(statusCode.rawValue)"
                        )
                    }
                    if let headers = eitherResponse.responseValue?.headers {
                        for (headerKey, eitherHeader) in headers {
                            if let reference = eitherHeader.reference {
                                try validateReference(
                                    reference,
                                    in: doc.components,
                                    location:
                                        "\(path.rawValue)/\(endpoint.method.rawValue)/responses/\(statusCode.rawValue)/headers/\(headerKey)"
                                )
                            } else if let headerValue = eitherHeader.headerValue {
                                if let schemaReference = headerValue.schemaOrContent.schemaReference {
                                    try validateReference(
                                        schemaReference,
                                        in: doc.components,
                                        location:
                                            "\(path.rawValue)/\(endpoint.method.rawValue)/responses/\(statusCode.rawValue)/headers/\(headerKey)"
                                    )
                                } else if let contentValue = headerValue.schemaOrContent.contentValue {
                                    try validateReferencesInContentTypes(
                                        contentValue,
                                        location:
                                            "\(path.rawValue)/\(endpoint.method.rawValue)/responses/\(statusCode.rawValue)/headers/\(headerKey)"
                                    )
                                }
                            }
                        }
                    }
                }
            }

            for eitherParameter in pathItem.parameters {
                if let reference = eitherParameter.reference {
                    try validateReference(reference, in: doc.components, location: "\(path.rawValue)/parameters")
                }
            }
        }
    }
}

/// Runs validation steps on the incoming OpenAPI document.
/// - Parameters:
///   - doc: The OpenAPI document to validate.
///   - config: The generator config.
/// - Returns: An array of diagnostic messages representing validation warnings.
/// - Throws: An error if a fatal issue is found.
func validateDoc(_ doc: ParsedOpenAPIRepresentation, config: Config) throws -> [Diagnostic] {
    try validateReferences(in: doc)
    try validateContentTypes(in: doc) { contentType in
        (try? _OpenAPIGeneratorCore.ContentType(string: contentType)) != nil
    }

    // Run OpenAPIKit's built-in validation.
    // Pass `false` to `strict`, however, because we don't
    // want to turn schema loading warnings into errors.
    // We already propagate the warnings to the generator's
    // diagnostics, so they get surfaced to the user.
    // But the warnings are often too strict and should not
    // block the generator from running.
    // Validation errors continue to be fatal, such as
    // structural issues, like non-unique operationIds, etc.
    let warnings = try doc.validate(using: Validator().validating(.operationsContainResponses), strict: false)
    let diagnostics: [Diagnostic] = warnings.map { warning in
        .warning(
            message: "Validation warning: \(warning.description)",
            context: [
                "codingPath": warning.codingPathString ?? "<none>", "contextString": warning.contextString ?? "<none>",
                "subjectName": warning.subjectName ?? "<none>",
            ]
        )
    }
    return diagnostics
}
