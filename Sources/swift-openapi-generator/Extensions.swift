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
import Foundation
import ArgumentParser
import _OpenAPIGeneratorCore
import Yams

#if $RetroactiveAttribute
extension URL: @retroactive ExpressibleByArgument {}
extension GeneratorMode: @retroactive ExpressibleByArgument {}
extension FeatureFlag: @retroactive ExpressibleByArgument {}
#else
extension URL: ExpressibleByArgument {}
extension GeneratorMode: ExpressibleByArgument {}
extension FeatureFlag: ExpressibleByArgument {}
#endif

extension URL {

    /// Creates a `URL` instance from a string argument.
    ///
    /// Initializes a `URL` instance using the path provided as an argument string.
    /// - Parameter argument: The string argument representing the path for the URL.
    public init?(argument: String) { self.init(fileURLWithPath: argument) }
}

extension CaseIterable where Self: RawRepresentable, Self.RawValue == String {

    /// A string representation of the raw values of all the cases,
    /// concatenated with a comma.
    static var prettyListing: String { allCases.map(\.rawValue).joined(separator: ", ") }
}

extension _UserConfig {

    /// An example configuration used in the command-line tool help section.
    static var sample: Self { .init(generate: [.types, .client], additionalImports: nil) }

    /// A YAML representation of the configuration.
    var yamlString: String { get throws { try YAMLEncoder().encode(self) } }
}

extension _UserConfig: CustomStringConvertible {
    var description: String { (try? yamlString) ?? "<unencodable config>" }
}
