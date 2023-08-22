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
import OpenAPIKit30

extension TypesFileTranslator {

    /// Returns a declaration of the Input type for the specified operation.
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: A structure declaration that represents the Input type.
    /// - Throws: An error if there's an issue during translation of the input type.
    func translateOperationInput(
        _ description: OperationDescription
    ) throws -> Declaration {

        let inputTypeName = description.inputTypeName

        func propertyBlueprintForNamespacedStruct(
            locatedIn location: OpenAPI.Parameter.Context.Location,
            withPropertiesFrom parameters: [UnresolvedParameter]
        ) throws -> PropertyBlueprint {
            let inputTypeName = description.inputTypeName
            let structTypeName = location.typeName(in: inputTypeName)
            let structProperties: [PropertyBlueprint] = try parameters.compactMap { parameter in
                try parseParameterAsProperty(
                    for: parameter,
                    inParent: inputTypeName
                )
            }
            let structDecl: Declaration = translateStructBlueprint(
                .init(
                    comment: nil,
                    access: config.access,
                    typeName: structTypeName,
                    conformances: Constants.Operation.Input.conformances,
                    properties: structProperties
                )
            )

            let defaultValue: PropertyBlueprint.DefaultValue?
            if structTypeName.asUsage.isOptional {
                // If inner struct is being used as an optional property, its default value in the
                // initializer of the outer struct is `nil`.
                defaultValue = .nil
            } else if structProperties.allSatisfy(\.typeUsage.isOptional) {
                // If inner struct is being used as an non-optional property, but it only has
                // optional inner properties, its default value in the initializer of the outer
                // struct is `.init()`.
                defaultValue = .emptyInit
            } else {
                // If inner struct is being used as an non-optional property, and has some fields
                // which must be specified then it must be provided explicitly to the initializer
                // of the outer struct.
                defaultValue = nil
            }

            return PropertyBlueprint(
                comment: nil,
                originalName: location.shortVariableName,
                typeUsage: structTypeName.asUsage,
                default: defaultValue,
                associatedDeclarations: [
                    structDecl
                ],
                asSwiftSafeName: swiftSafeName
            )
        }
        let bodyProperty = try parseRequestBodyAsProperty(
            for: description.operation.requestBody,
            inParent: inputTypeName
        )

        let inputStructDecl = translateStructBlueprint(
            .init(
                comment: nil,
                access: config.access,
                typeName: inputTypeName,
                conformances: Constants.Operation.Input.conformances,
                properties: [
                    try propertyBlueprintForNamespacedStruct(
                        locatedIn: .path,
                        withPropertiesFrom: description.allPathParameters
                    ),
                    try propertyBlueprintForNamespacedStruct(
                        locatedIn: .query,
                        withPropertiesFrom: description.allQueryParameters
                    ),
                    try propertyBlueprintForNamespacedStruct(
                        locatedIn: .header,
                        withPropertiesFrom: description.allHeaderParameters
                    ),
                    try propertyBlueprintForNamespacedStruct(
                        locatedIn: .cookie,
                        withPropertiesFrom: description.allCookieParameters
                    ),
                    bodyProperty,
                ]
            )
        )
        return inputStructDecl
    }

    /// Returns a declaration of the Output type for the specified operation.
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: An enum declaration that represents the Output type.
    /// - Throws: An error if there's an issue during translation of the output type.
    func translateOperationOutput(
        _ description: OperationDescription
    ) throws -> Declaration {

        let outputTypeName = description.outputTypeName

        let documentedOutcomes =
            try description
            .operation
            .responseOutcomes
            .map { outcome in
                try translateResponseOutcomeInTypes(
                    outcome,
                    operation: description,
                    operationJSONPath: description.jsonPathComponent
                )
            }
        let documentedMembers: [Declaration] =
            documentedOutcomes
            .flatMap { inlineResponseDecl, caseDecl in
                guard let inlineResponseDecl else {
                    return [caseDecl]
                }
                return [inlineResponseDecl, caseDecl]
            }

        let allMembers: [Declaration]
        if description.containsDefaultResponse {
            allMembers = documentedMembers
        } else {
            let undocumentedDecl: Declaration = .commentable(
                .doc(
                    #"""
                    Undocumented response.

                    A response with a code that is not documented in the OpenAPI document.
                    """#
                ),
                .enumCase(
                    name: Constants.Operation.Output.undocumentedCaseName,
                    kind: .nameWithAssociatedValues([
                        .init(label: "statusCode", type: TypeName.int.shortSwiftName),
                        .init(type: TypeName.undocumentedPayload.fullyQualifiedSwiftName),
                    ])
                )
            )
            allMembers = documentedMembers + [undocumentedDecl]
        }

        let enumDecl: Declaration = .enum(
            isFrozen: true,
            accessModifier: config.access,
            name: outputTypeName.shortSwiftName,
            conformances: Constants.Operation.Output.conformances,
            members: allMembers
        )
        return enumDecl
    }

    /// Returns a declaration of the namespace type of the specified operation.
    ///
    /// The namespace type is the parent type of the operation's Input and
    /// Output types, and ties the two types together.
    /// - Parameter operation: The OpenAPI operation.
    /// - Returns: An enum declaration that represents the operation's
    /// namespace.
    /// - Throws: An error if there's an issue during translation of the operation's namespace.
    func translateOperation(
        _ operation: OperationDescription
    ) throws -> Declaration {

        let idPropertyDecl: Declaration = .variable(
            .init(
                accessModifier: config.access,
                isStatic: true,
                kind: .let,
                left: "id",
                type: "String",
                right: .literal(operation.operationID)
            )
        )

        let inputDecl: Declaration = try translateOperationInput(operation)
        let outputDecl: Declaration = try translateOperationOutput(operation)

        let operationNamespace = operation.operationNamespace
        let operationEnumDecl = Declaration.commentable(
            operation.comment,
            .enum(
                .init(
                    accessModifier: config.access,
                    name: operationNamespace.shortSwiftName,
                    members: [
                        idPropertyDecl,
                        inputDecl,
                        outputDecl,
                    ]
                )
            )
        )
        return operationEnumDecl
    }

    /// Returns a declaration of a code block that contains the namespace
    /// for all the operations defined in the OpenAPI document.
    /// - Parameter operations: The operations defined in the OpenAPI document.
    /// - Returns: A code block that contains an enum declaration with a
    /// separate namespace type for each operation.
    /// - Throws: An error if there is an issue during operation translation.
    func translateOperations(
        _ operations: [OperationDescription]
    ) throws -> CodeBlock {

        let operationDecls = try operations.map(translateOperation)

        let operationsEnum = CodeBlock(
            comment: .operationsNamespace(),
            item: .declaration(
                .enum(
                    .init(
                        accessModifier: config.access,
                        name: Constants.Operations.namespace,
                        members: operationDecls
                    )
                )
            )
        )
        return operationsEnum
    }
}
