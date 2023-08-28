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
import OpenAPIKit

/// A message emitted by the generator.
public struct Diagnostic: Error, Codable {

    /// Describes the severity of a diagnostic.
    public enum Severity: String, Codable, Sendable {

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

    /// Describes the source file that triggered a diagnostic.
    public struct Location: Codable, Sendable {
        /// The absolute path to a specific source file that triggered the diagnostic.
        public var filePath: String

        /// The line number (if known) of the line within the source file that triggered the diagnostic.
        public var lineNumber: Int?
    }

    /// The source file that triggered the diagnostic.
    public var location: Location?

    /// Additional information about where the issue occurred.
    public var context: [String: String] = [:]

    /// Creates an informative message, which doesn't represent an issue.
    public static func note(message: String, location: Location? = nil, context: [String: String] = [:]) -> Diagnostic {
        .init(severity: .note, message: message, location: location, context: context)
    }

    /// Creates a recoverable issue, which doesn't prevent the generator
    /// from continuing.
    /// - Parameters:
    ///   - message: The message that describes the warning.
    ///   - location: Describe the source file that triggered the diagnostic (if known).
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: A warning diagnostic.
    public static func warning(
        message: String,
        location: Location? = nil,
        context: [String: String] = [:]
    ) -> Diagnostic {
        .init(severity: .warning, message: message, location: location, context: context)
    }

    /// Creates a non-recoverable issue, which leads the generator to stop.
    /// - Parameters:
    ///   - message: The message that describes the error.
    ///   - location: Describe the source file that triggered the diagnostic (if known).
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: An error diagnostic.
    public static func error(
        message: String,
        location: Location? = nil,
        context: [String: String] = [:]
    ) -> Diagnostic {
        .init(severity: .error, message: message, location: location, context: context)
    }

    /// Creates a diagnostic for an unsupported feature.
    ///
    /// Recoverable, the generator skips the unsupported feature.
    /// - Parameters:
    ///   - feature: A human-readable name of the feature.
    ///   - foundIn: A description of the location in which the unsupported
    ///   feature was detected.
    ///   - location: Describe the source file that triggered the diagnostic (if known).
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: A warning diagnostic.
    public static func unsupported(
        _ feature: String,
        foundIn: String,
        location: Location? = nil,
        context: [String: String] = [:]
    ) -> Diagnostic {
        var context = context
        context["foundIn"] = foundIn
        return warning(
            message: "Feature \"\(feature)\" is not supported, skipping",
            location: location,
            context: context
        )
    }

    /// Creates a diagnostic for an unsupported schema.
    /// - Parameters:
    ///   - reason: A human-readable reason.
    ///   - schema: The unsupported JSON schema.
    ///   - foundIn: A description of the location in which the unsupported
    ///   schema was detected.
    ///   - location: Describe the source file that triggered the diagnostic (if known).
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    /// - Returns: A warning diagnostic.
    public static func unsupportedSchema(
        reason: String,
        schema: JSONSchema,
        foundIn: String,
        location: Location? = nil,
        context: [String: String] = [:]
    ) -> Diagnostic {
        var context = context
        context["foundIn"] = foundIn
        return warning(
            message: "Schema \"\(schema.prettyDescription)\" is not supported, reason: \"\(reason)\", skipping",
            location: location,
            context: context
        )
    }
}

extension Diagnostic.Severity: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension Diagnostic: CustomStringConvertible {
    public var description: String {
        var prefix = ""
        if let location = location {
            prefix = "\(location.filePath):"
            if let line = location.lineNumber {
                prefix += "\(line):"
            }
            prefix += " "
        }
        let contextString = context.map { "\($0)=\($1)" }.sorted().joined(separator: ", ")
        return "\(prefix)\(severity): \(message)\(contextString.isEmpty ? "" : " [context: \(contextString)]")"
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

    /// Emits a diagnostic for an unsupported schema found in the specified
    /// string location.
    /// - Parameters:
    ///   - reason: A human-readable reason.
    ///   - schema: The unsupported JSON schema.
    ///   - foundIn: A description of the location in which the unsupported
    ///   schema was detected.
    ///   - context: A set of key-value pairs that help the user understand
    ///   where the warning occurred.
    func emitUnsupportedSchema(
        reason: String,
        schema: JSONSchema,
        foundIn: String,
        context: [String: String] = [:]
    ) {
        emit(
            Diagnostic.unsupportedSchema(
                reason: reason,
                schema: schema,
                foundIn: foundIn,
                context: context
            )
        )
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
        stdErrHandle.write(diagnostic.description)
    }
}

/// A no-op collector, silently ignores all diagnostics.
///
/// Useful when diagnostics can be ignored.
struct QuietDiagnosticCollector: DiagnosticCollector {
    func emit(_ diagnostic: Diagnostic) {}
}
