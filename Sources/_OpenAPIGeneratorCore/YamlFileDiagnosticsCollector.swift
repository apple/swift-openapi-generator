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
import Yams

struct _DiagnosticsYamlFileContent: Encodable {
    var uniqueMessages: [String]
    var diagnostics: [Diagnostic]
}

/// A collector that writes diagnostics to a YAML file.
final class _YamlFileDiagnosticsCollector: DiagnosticCollector, @unchecked Sendable {
    /// Protects `diagnostics`.
    private let lock = NSLock()

    /// A list of collected diagnostics.
    private var diagnostics: [Diagnostic] = []

    /// A file path where to persist the YAML file.
    private let url: URL

    /// Creates a new collector.
    /// - Parameter url: A file path where to persist the YAML file.
    init(url: URL) { self.url = url }

    func emit(_ diagnostic: Diagnostic) {
        lock.lock()
        defer { lock.unlock() }
        diagnostics.append(diagnostic)
    }

    /// Finishes writing to the collector by persisting the accumulated
    /// diagnostics to a YAML file.
    func finalize() throws {
        lock.lock()
        defer { lock.unlock() }
        let sortedDiagnostics = diagnostics.sorted(by: { a, b in a.description < b.description })
        let uniqueMessages = Set(sortedDiagnostics.map(\.message)).sorted()
        let encoder = YAMLEncoder()
        encoder.options.sortKeys = true
        let container = _DiagnosticsYamlFileContent(uniqueMessages: uniqueMessages, diagnostics: sortedDiagnostics)
        try encoder.encode(container).write(to: url, atomically: true, encoding: .utf8)
    }
}
