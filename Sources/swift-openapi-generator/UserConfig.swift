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
import _OpenAPIGeneratorCore

/// A set of configuration values provided by the user.
///
/// In contrast to `Config`, `_UserConfig` supports running multiple invocations
/// of the generator pipeline, and, for example, generate both Types.swift and
/// Client.swift in one invocation of the command-line tool.
struct _UserConfig: Codable {

    /// A list of modes to use, in other words, which Swift files to generate.
    var generate: [GeneratorMode]

    /// The access modifier used for the API of generated code.
    var accessModifier: AccessModifier?

    /// A list of names of additional imports that are added to every
    /// generated Swift file.
    var additionalImports: [String]?

    /// Filter to apply to the OpenAPI document before generation.
    var filter: DocumentFilter?

    /// A set of features to explicitly enable.
    var featureFlags: FeatureFlags?

    /// A set of raw values corresponding to the coding keys of this struct.
    static let codingKeysRawValues = Set(CodingKeys.allCases.map({ $0.rawValue }))

    enum CodingKeys: String, CaseIterable, CodingKey {
        case generate
        case accessModifier
        case additionalImports
        case filter
        case featureFlags
    }
}
