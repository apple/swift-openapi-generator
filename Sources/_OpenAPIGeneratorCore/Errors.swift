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

/// An error representing a fatal issue encountered by the generator.
///
/// Use sparingly, as recoverable issues should instead be emitted as
/// a ``Diagnostic`` into a ``DiagnosticCollector``.
struct GenericError: Error {

    /// The message describing the issue.
    var message: String
}

extension GenericError: CustomStringConvertible { var description: String { message } }

extension GenericError: LocalizedError { var errorDescription: String? { description } }
