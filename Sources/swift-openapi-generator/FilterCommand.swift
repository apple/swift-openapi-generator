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
import ArgumentParser
import Foundation
import _OpenAPIGeneratorCore
import Yams
import OpenAPIKit
import OpenAPIKit30

struct _FilterCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "filter",
        abstract: "Filter an OpenAPI document",
        discussion: """
            Filtering rules are provided in a YAML configuration file.

            Example configuration file contents:

            ```yaml
            \(try! YAMLEncoder().encode(sampleConfig))
            ```
            """
    )

    @Option(help: "Path to a YAML configuration file.")
    var config: URL

    @Argument(help: "Path to the OpenAPI document, either in YAML or JSON.")
    var docPath: URL

    func parseOpenAPIDocument(_ documentData: Data) throws -> OpenAPIKit.OpenAPI.Document {
        let decoder = YAMLDecoder()

        struct OpenAPIVersionedDocument: Decodable {
            var openapi: String
        }

        let versionedDocument = try decoder.decode(OpenAPIVersionedDocument.self, from: documentData)

        let document: OpenAPIKit.OpenAPI.Document
        switch versionedDocument.openapi {
        case "3.0.0", "3.0.1", "3.0.2", "3.0.3":
            let document30x = try decoder.decode(OpenAPIKit30.OpenAPI.Document.self, from: documentData)
            document = document30x.convert(to: .v3_1_0)
        case "3.1.0":
            document = try decoder.decode(OpenAPIKit.OpenAPI.Document.self, from: documentData)
        default:
            fatalError("Unsupported OpenAPI version found: \(versionedDocument.openapi)")
        }
        return document
    }

    func run() async throws {
        let configData = try Data(contentsOf: config)
        let config = try YAMLDecoder().decode(_UserConfig.self, from: configData)
        let document = try timing("Parsing document", parseOpenAPIDocument(Data(contentsOf: docPath)))
        try document.validate()
        guard let documentFilter = config.filter else {
            FileHandle.standardError.write("warning: No filter config provided\n")
            FileHandle.standardOutput.write(try YAMLEncoder().encode(document))
            return
        }
        let filteredDocument = try timing("Filtering document", documentFilter.filter(document))
        FileHandle.standardOutput.write(try YAMLEncoder().encode(filteredDocument))
    }
}

private func timing<Output>(_ title: String, operation: () throws -> Output) rethrows -> Output {
    FileHandle.standardError.write("\(title)...\n")
    let start = Date.timeIntervalSinceReferenceDate
    let result = try operation()
    let diff = Date.timeIntervalSinceReferenceDate - start
    FileHandle.standardError.write(String(format: "\(title) complete! (%.2fs)\n", diff))
    return result
}

private func timing<Output>(_ title: String, _ operation: @autoclosure () throws -> Output) rethrows -> Output {
    try timing(title, operation: operation)
}

private let sampleConfig = _UserConfig(
    generate: [],
    filter: DocumentFilter(
        tags: ["greetings"],
        paths: ["/greeting"],
        schemas: ["Greeting"]
    )
)
