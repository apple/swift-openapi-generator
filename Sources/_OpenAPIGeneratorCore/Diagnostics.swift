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
import OpenAPIKit30

/// A message emitted by the generator.
public struct Diagnostic: Error, Codable {

    /// Describes the severity of a diagnostic.
    public enum Severity: String, Codable {

        /// An informative message, does not represent an issue.
        case note

        /// A non-fatal issue that should be addressed, but the generator is
        /// able to recover.
        case warning

        /// A fatal issue from which the generator cannot recover.
        case error
    }

    /// The severity of the diagnostic.
    public var severity: Severity

    /// A user-friendly description of the diagnostic.
    public var message: String

    /// Additional information about where the issue occurred.
    public var context: [String: String] = [:]

    /// Creates an informative message, which doesn't represent an issue.
    public static func note(message: String, context: [String: String] = [:]) -> Diagnostic {
        .init(severity: .note, message: message, context: context)
    }

    /// Creates a recoverable issue, which doesn't prevent the generator
    /// from continuing.
    /// - Parameters:
    ///   - message: The message that describes the warning.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: A warning diagnostic.
    public static func warning(
        message: String,
        context: [String: String] = [:]
    ) -> Diagnostic {
        .init(severity: .warning, message: message, context: context)
    }

    /// Creates a non-recoverable issue, which leads the generator to stop.
    /// - Parameters:
    ///   - message: The message that describes the error.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: An error diagnostic.
    public static func error(
        message: String,
        context: [String: String] = [:]
    ) -> Diagnostic {
        .init(severity: .error, message: message, context: context)
    }

    /// Creates a diagnostic for an unsupported feature.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: A warning diagnostic.
    public static func unsupported(
        _ feature: String,
        foundIn: String,
        context: [String: String] = [:]
    ) -> Diagnostic {
        var context = context
        context["foundIn"] = foundIn
        return warning(message: "Feature \"\(feature)\" is not supported, skipping", context: context)
    }
}

extension Diagnostic.Severity: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension Diagnostic: CustomStringConvertible {
    public var description: String {
        let contextString = context.map { "\($0)=\($1)" }.sorted().joined(separator: ", ")
        return "\(severity): \(message) [\(contextString.isEmpty ? "" : "context: \(contextString)")]"
    }
}

extension Diagnostic: LocalizedError {
    public var errorDescription: String? {
        description
    }
}

/// A type that receives diagnostics.
///
/// The collector can process, log, or store the diagnostics.
///
/// See concrete implementations for several variants of the collector.
public protocol DiagnosticCollector {

    /// Submits a diagnostic to the collector.
    /// - Parameter diagnostic: The diagnostic to submit.
    func emit(_ diagnostic: Diagnostic)
}

extension DiagnosticCollector {

    /// Emits a diagnostic for an unsupported feature found in the specified
    /// string location.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupported(
        _ feature: String,
        foundIn: String,
        context: [String: String] = [:]
    ) {
        emit(Diagnostic.unsupported(feature, foundIn: foundIn, context: context))
    }

    /// Emits a diagnostic for an unsupported feature found in the specified
    /// type name.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: The type name related to where the issue was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupported(
        _ feature: String,
        foundIn: TypeName,
        context: [String: String] = [:]
    ) {
        emit(Diagnostic.unsupported(feature, foundIn: foundIn.description, context: context))
    }

    /// Emits a diagnostic for an unsupported feature found in the specified
    /// string location when the test closure returns a non-nil value.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - test: A closure that returns a non-nil value when an unsupported
    ///   feature is specified in the OpenAPI document.
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupportedIfNotNil(
        _ test: Any?,
        _ feature: String,
        foundIn: String,
        context: [String: String] = [:]
    ) {
        if test == nil {
            return
        }
        emitUnsupported(feature, foundIn: foundIn, context: context)
    }

    /// Emits a diagnostic for an unsupported feature found in the specified
    /// string location when the test collection is not empty.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - test: A collection that is not empty if the unsupported feature
    ///   is specified in the OpenAPI document.
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupportedIfNotEmpty<C: Collection>(
        _ test: C?,
        _ feature: String,
        foundIn: String,
        context: [String: String] = [:]
    ) {
        guard let test = test, !test.isEmpty else {
            return
        }
        emitUnsupported(feature, foundIn: foundIn, context: context)
    }

    /// Emits a diagnostic for an unsupported feature found in the specified
    /// string location when the test Boolean value is true.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - test: A Boolean value that indicates whether the unsupported
    ///   feature is specified in the OpenAPI document.
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupportedIfTrue(
        _ test: Bool,
        _ feature: String,
        foundIn: String,
        context: [String: String] = [:]
    ) {
        if !test {
            return
        }
        emitUnsupported(feature, foundIn: foundIn, context: context)
    }
}

/// A diagnostic collector that prints diagnostics to standard output.
struct PrintingDiagnosticCollector: DiagnosticCollector {

    /// Creates a new collector.
    public init() {}

    public func emit(_ diagnostic: Diagnostic) {
        print(diagnostic.description)
    }
}

/// A diagnostic collector that prints diagnostics to standard error.
public struct StdErrPrintingDiagnosticCollector: DiagnosticCollector {

    /// Creates a new collector.
    public init() {}

    public func emit(_ diagnostic: Diagnostic) {
        print(diagnostic.description, to: &stdErrHandle)
    }
}

/// A no-op collector, silently ignores all diagnostics.
///
/// Useful when diagnostics can be ignored.
struct QuietDiagnosticCollector: DiagnosticCollector {
    func emit(_ diagnostic: Diagnostic) {}
}
