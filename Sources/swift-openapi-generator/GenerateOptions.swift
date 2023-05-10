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
import Yams
import OpenAPIKit30
import _OpenAPIGeneratorCore

struct _GenerateOptions: ParsableArguments {

    @Argument(help: "Path to the OpenAPI document, either in YAML or JSON.")
    var docPath: URL

    @Option(help: "Path to a YAML configuration file.")
    var config: URL?

    @Option(
        help:
            "The Swift files to generate. Options: \(GeneratorMode.prettyListing). Note that '\(GeneratorMode.client.rawValue)' and '\(GeneratorMode.server.rawValue)' depend on declarations in '\(GeneratorMode.types.rawValue)'."
    )
    var mode: [GeneratorMode] = []

    @Option(help: "Additional imports to add to all generated files.")
    var additionalImport: [String] = []

    @Option(
        help: "When specified, writes out the diagnostics into a YAML file instead of emitting them to standard error."
    )
    var diagnosticsOutputPath: URL?
}

extension _GenerateOptions {

    /// The user-provided user config, not yet resolved with defaults.
    var resolvedUserConfig: _UserConfig {
        get throws {
            let config = try loadedConfig()
            return try .init(
                generate: resolvedModes(config),
                additionalImports: resolvedAdditionalImports(config)
            )
        }
    }

    /// Returns a list of the generator modes requested by the user.
    /// - Parameter config: The configuration specified by the user.
    func resolvedModes(_ config: _UserConfig?) throws -> [GeneratorMode] {
        if !mode.isEmpty {
            return mode
        }
        guard let config else {
            throw ValidationError("Must either provide a config file or specify --mode.")
        }
        return Set(config.generate).sorted()
    }

    /// Returns a list of additional imports requested by the user.
    /// - Parameter config: The configuration specified by the user.
    func resolvedAdditionalImports(_ config: _UserConfig?) -> [String] {
        if !additionalImport.isEmpty {
            return additionalImport
        }
        if let additionalImports = config?.additionalImports, !additionalImports.isEmpty {
            return additionalImports
        }
        return []
    }

    /// Returns the configuration requested by the user.
    ///
    /// - Returns: Loaded configuration, if found and parsed successfully.
    /// Nil if the user provided no configuration file path.
    func loadedConfig() throws -> _UserConfig? {
        guard let config else {
            return nil
        }
        do {
            let data = try Data(contentsOf: config)
            let config = try YAMLDecoder().decode(_UserConfig.self, from: data)
            return config
        } catch {
            throw ValidationError("Failed to load config at path \(config.path), error: \(error)")
        }
    }
}
