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
import OpenAPIKit
import _OpenAPIGeneratorCore

struct _GenerateOptions: ParsableArguments {

    @Argument(help: "Path to the OpenAPI document, either in YAML or JSON.") var docPath: URL

    @Option(help: "Path to a YAML configuration file.") var config: URL?

    @Option(
        help:
            "The Swift files to generate. Options: \(GeneratorMode.prettyListing). Note that '\(GeneratorMode.client.rawValue)' and '\(GeneratorMode.server.rawValue)' depend on declarations in '\(GeneratorMode.types.rawValue)'."
    ) var mode: [GeneratorMode] = []

    @Option(
        help:
            "The access modifier to use for the API of generated code. Default: \(Config.defaultAccessModifier.rawValue)"
    ) var accessModifier: AccessModifier?

    @Option(help: "Additional import to add to all generated files.") var additionalImport: [String] = []

    @Option(help: "Pre-release feature to enable. Options: \(FeatureFlag.prettyListing).") var featureFlag:
        [FeatureFlag] = []

    @Option(
        help: "When specified, writes out the diagnostics into a YAML file instead of emitting them to standard error."
    ) var diagnosticsOutputPath: URL?
}

extension AccessModifier: ExpressibleByArgument {}

extension _GenerateOptions {

    /// Returns a list of the generator modes requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: A list of generator modes requested by the user.
    /// - Throws: A `ValidationError` if no modes are provided and no configuration is available.
    func resolvedModes(_ config: _UserConfig?) throws -> [GeneratorMode] {
        if !mode.isEmpty { return mode }
        guard let config else { throw ValidationError("Must either provide a config file or specify --mode.") }
        return Set(config.generate).sorted()
    }

    /// Returns the access modifier requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: The access modifier requested by the user, or nil if the default should be used.
    func resolvedAccessModifier(_ config: _UserConfig?) -> AccessModifier? {
        if let accessModifier { return accessModifier }
        if let accessModifier = config?.accessModifier { return accessModifier }
        return nil
    }

    /// Returns a list of additional imports requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: A list of additional import statements requested by the user.
    func resolvedAdditionalImports(_ config: _UserConfig?) -> [String] {
        if !additionalImport.isEmpty { return additionalImport }
        if let additionalImports = config?.additionalImports, !additionalImports.isEmpty { return additionalImports }
        return []
    }

    /// Returns the naming strategy requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: The naming strategy requestd by the user.
    func resolvedNamingStrategy(_ config: _UserConfig?) -> NamingStrategy { config?.namingStrategy ?? .defensive }

    /// Returns the name overrides requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: The name overrides requested by the user
    func resolvedNameOverrides(_ config: _UserConfig?) -> [String: String] { config?.nameOverrides ?? [:] }

    /// Returns a list of the feature flags requested by the user.
    /// - Parameter config: The configuration specified by the user.
    /// - Returns: A set of feature flags requested by the user.
    func resolvedFeatureFlags(_ config: _UserConfig?) -> FeatureFlags {
        if !featureFlag.isEmpty { return Set(featureFlag) }
        return config?.featureFlags ?? []
    }

    /// Validates a collection of keys against a predefined set of allowed keys.
    ///
    /// - Parameter keys: A collection of keys to be validated.
    /// - Throws: A `ValidationError` if any key in the collection is not found in the
    ///           allowed set of keys specified by `_UserConfig.codingKeysRawValues`.
    func validateKeys(_ keys: [String]) throws {
        for key in keys {
            if !_UserConfig.codingKeysRawValues.contains(key) {
                throw ValidationError("Unknown configuration key found in config file: \(key)")
            }
        }
    }

    /// Returns the configuration requested by the user.
    ///
    /// - Returns: Loaded configuration, if found and parsed successfully.
    /// Nil if the user provided no configuration file path.
    /// - Throws: A `ValidationError` if loading or parsing the configuration file encounters an error.
    func loadedConfig() throws -> _UserConfig? {
        guard let config else { return nil }
        do {
            let data = try Data(contentsOf: config)
            let configAsString = String(decoding: data, as: UTF8.self)
            var yamlKeys: [String] = []

            do { yamlKeys = try YamsParser.extractTopLevelKeys(fromYAMLString: configAsString) } catch {
                throw ValidationError("The config isn't valid. \(error)")
            }
            try validateKeys(yamlKeys)

            let config = try YAMLDecoder().decode(_UserConfig.self, from: data)
            return config
        } catch { throw ValidationError("Failed to load config at path \(config.path), error: \(error)") }
    }
}
