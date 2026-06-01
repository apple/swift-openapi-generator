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

/// A translator for the generated common types.
///
/// Types.swift is the Swift file containing all the reusable types from
/// the "Components" section in the OpenAPI document, as well as all of the
/// namespaces for each OpenAPI operation, including their Input and Output
/// types.
///
/// Types generated in this file are depended on by both Client.swift and
/// Server.swift.
struct TypesFileTranslator: FileTranslator {

    var config: Config
    var diagnostics: any DiagnosticCollector
    var components: OpenAPI.Components

    func translateFile(parsedOpenAPI: ParsedOpenAPIRepresentation) throws -> StructuredSwiftRepresentation {

        let doc = parsedOpenAPI

        let topComment = self.topComment

        let imports = Constants.File.imports + config.additionalImports.map { ImportDescription(moduleName: $0) }

        let apiProtocol = try translateAPIProtocol(doc.paths)

        let apiProtocolExtension = try translateAPIProtocolExtension(doc.paths)

        let serversDecl = translateServers(doc.servers)

        let multipartSchemaNames = try parseSchemaNamesUsedInMultipart(paths: doc.paths, components: doc.components)

        let operationDescriptions = try OperationDescription.all(from: doc.paths, in: doc.components, context: context)

        if let shardingConfig = config.sharding {
            return try translateFileSharded(
                doc: doc,
                topComment: topComment,
                imports: imports,
                apiProtocol: apiProtocol,
                apiProtocolExtension: apiProtocolExtension,
                serversDecl: serversDecl,
                multipartSchemaNames: multipartSchemaNames,
                operationDescriptions: operationDescriptions,
                shardingConfig: shardingConfig
            )
        }

        let operations = try translateOperations(operationDescriptions)

        let components = try translateComponents(doc.components, multipartSchemaNames: multipartSchemaNames)

        let typesFile = FileDescription(
            topComment: topComment,
            imports: imports,
            codeBlocks: [
                .declaration(apiProtocol), .declaration(apiProtocolExtension), .declaration(serversDecl), components,
                operations,
            ]
        )

        return StructuredSwiftRepresentation(file: .init(name: GeneratorMode.types.outputFileName, contents: typesFile))
    }

    private func translateFileSharded(
        doc: ParsedOpenAPIRepresentation,
        topComment: Comment,
        imports: [ImportDescription],
        apiProtocol: Declaration,
        apiProtocolExtension: Declaration,
        serversDecl: Declaration,
        multipartSchemaNames: Set<OpenAPI.ComponentKey>,
        operationDescriptions: [OperationDescription],
        shardingConfig: ShardingConfig
    ) throws -> StructuredSwiftRepresentation {
        try shardingConfig.validate()

        let naming: ShardNamingStrategy = if let prefix = shardingConfig.modulePrefix {
            .prefixed(modulePrefix: prefix)
        } else {
            .default
        }
        let importResolver = ShardImportResolver(config: shardingConfig, naming: naming)

        let shardedSchemas = try translateSchemasSharded(
            doc.components.schemas,
            multipartSchemaNames: multipartSchemaNames,
            shardingConfig: shardingConfig,
            naming: naming
        )

        let shardedOperations = try translateOperationsSharded(
            operationDescriptions,
            schemaGraph: shardedSchemas.graph,
            maxLayer: shardedSchemas.maxLayer,
            shardingConfig: shardingConfig,
            naming: naming
        )

        let parameters = try translateComponentParameters(doc.components.parameters)
        let requestBodies = try translateComponentRequestBodies(doc.components.requestBodies)
        let responses = try translateComponentResponses(doc.components.responses)
        let headers = try translateComponentHeaders(doc.components.headers)

        var allFiles: [NamedFileDescription] = []

        allFiles.append(assembleRootFile(
            topComment: topComment,
            imports: imports,
            exportedImports: importResolver.exportedImportsForRootFile(maxLayer: shardedSchemas.maxLayer),
            apiProtocol: apiProtocol,
            apiProtocolExtension: apiProtocolExtension
        ))

        allFiles.append(contentsOf: assembleComponentFiles(
            shardedSchemas: shardedSchemas,
            naming: naming,
            importResolver: importResolver,
            topComment: topComment,
            imports: imports,
            parameters: parameters,
            requestBodies: requestBodies,
            responses: responses,
            headers: headers
        ))

        allFiles.append(contentsOf: assembleOperationFiles(
            shardedOperations: shardedOperations,
            naming: naming,
            importResolver: importResolver,
            topComment: topComment,
            imports: imports,
            serversDecl: serversDecl
        ))

        return StructuredSwiftRepresentation(files: allFiles)
    }

    private func assembleRootFile(
        topComment: Comment,
        imports: [ImportDescription],
        exportedImports: [ImportDescription] = [],
        apiProtocol: Declaration,
        apiProtocolExtension: Declaration
    ) -> NamedFileDescription {
        NamedFileDescription(
            name: "Types_root.swift",
            contents: FileDescription(
                topComment: topComment,
                imports: imports + exportedImports,
                codeBlocks: [
                    .declaration(apiProtocol),
                    .declaration(apiProtocolExtension),
                ]
            )
        )
    }

    private func assembleComponentFiles(
        shardedSchemas: ShardedSchemaResult,
        naming: ShardNamingStrategy,
        importResolver: ShardImportResolver,
        topComment: Comment,
        imports: [ImportDescription],
        parameters: Declaration,
        requestBodies: Declaration,
        responses: Declaration,
        headers: Declaration
    ) -> [NamedFileDescription] {
        let emptySchemasDecl: Declaration = .commentable(
            JSONSchema.sectionComment(),
            .enum(accessModifier: config.access, name: Constants.Components.Schemas.namespace, members: [])
        )
        let componentsDecl: Declaration = .commentable(
            .doc("Types generated from the components section of the OpenAPI document."),
            .enum(.init(
                accessModifier: config.access,
                name: "Components",
                members: [emptySchemasDecl, parameters, requestBodies, responses, headers]
            ))
        )

        var files: [NamedFileDescription] = []

        files.append(NamedFileDescription(
            name: naming.componentsBaseFileName,
            contents: FileDescription(
                topComment: topComment,
                imports: imports,
                codeBlocks: [.declaration(componentsDecl)]
            )
        ))

        for file in shardedSchemas.files {
            let schemasExtension: Declaration = .extension(
                .init(onType: "Components.Schemas", declarations: file.declarations)
            )
            let isComponentLayer = file.layer == 0
            let additionalImports = isComponentLayer
                ? importResolver.componentShardImports()
                : importResolver.typeLayerShardImports(layerIndex: file.layer - 1)
            files.append(NamedFileDescription(
                name: file.fileName,
                contents: FileDescription(
                    topComment: topComment,
                    imports: imports + additionalImports,
                    codeBlocks: file.declarations.isEmpty ? [] : [.declaration(schemasExtension)]
                )
            ))
        }

        return files
    }

    private func assembleOperationFiles(
        shardedOperations: ShardedOperationResult,
        naming: ShardNamingStrategy,
        importResolver: ShardImportResolver,
        topComment: Comment,
        imports: [ImportDescription],
        serversDecl: Declaration
    ) -> [NamedFileDescription] {
        var files: [NamedFileDescription] = []

        let emptyOperationsEnum: Declaration = .enum(
            .init(accessModifier: config.access, name: Constants.Operations.namespace, members: [])
        )
        files.append(NamedFileDescription(
            name: naming.operationsBaseFileName,
            contents: FileDescription(
                topComment: topComment,
                imports: imports,
                codeBlocks: [.declaration(serversDecl), .declaration(emptyOperationsEnum)]
            )
        ))

        for file in shardedOperations.files {
            let operationsExtension: Declaration = .extension(
                .init(onType: Constants.Operations.namespace, declarations: file.declarations)
            )
            files.append(NamedFileDescription(
                name: file.fileName,
                contents: FileDescription(
                    topComment: topComment,
                    imports: imports + importResolver.operationShardImports(layerIndex: file.layer),
                    codeBlocks: file.declarations.isEmpty ? [] : [.declaration(operationsExtension)]
                )
            ))
        }

        return files
    }
}
