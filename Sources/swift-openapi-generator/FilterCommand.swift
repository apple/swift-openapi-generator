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

struct _FilterCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
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

    @Option(help: "Path to a YAML configuration file.") var config: URL

    @Option(help: "Output format, either \(OutputFormat.yaml.rawValue) or \(OutputFormat.json.rawValue).")
    var outputFormat: OutputFormat = .yaml

    @Argument(help: "Path to the OpenAPI document, either in YAML or JSON.") var docPath: URL

    func run() async throws {
        let configData = try Data(contentsOf: config)
        let config = try YAMLDecoder().decode(_UserConfig.self, from: configData)
        let documentInput = try InMemoryInputFile(absolutePath: docPath, contents: Data(contentsOf: docPath))
        let document = try timing(
            "Parsing document",
            YamsParser.parseOpenAPIDocument(documentInput, diagnostics: StdErrPrintingDiagnosticCollector())
        )
        guard let documentFilter = config.filter else {
            FileHandle.standardError.write("warning: No filter config provided\n")
            FileHandle.standardOutput.write(try encode(document, outputFormat))
            return
        }
        let filteredDocument = try timing("Filtering document", documentFilter.filter(document))
        FileHandle.standardOutput.write(try encode(filteredDocument, outputFormat))
    }
}

private func encode(_ document: OpenAPI.Document, _ format: OutputFormat) throws -> Data {
    switch format {
    case .yaml: return Data(try YAMLEncoder().encode(document).utf8)
    case .json:
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        return try encoder.encode(document)
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
        operations: ["getGreeting"],
        tags: ["greetings"],
        paths: ["/greeting"],
        schemas: ["Greeting"]
    )
)

enum OutputFormat: String, ExpressibleByArgument {
    case json
    case yaml
}
