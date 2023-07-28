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

extension FileTranslator {

    /// Returns a copy of the string modified to be a valid Swift identifier.
    ///
    /// - Parameter string: The string to convert to be safe for Swift.
    func swiftSafeName(for string: String) -> String {
        guard config.featureFlags.contains(.proposal0001) else {
            return string.safeForSwiftCode
        }
        return string.proposedSafeForSwiftCode
    }
}

fileprivate extension String {

    /// Returns a string sanitized to be usable as a Swift identifier.
    ///
    /// For example, the string `$nake` would be returned as `_nake`, because
    /// the dollar sign is not a valid character in a Swift identifier.
    ///
    /// In addition to replacing illegal characters with an underscores, also
    /// ensures that the identifier starts with a letter and not a number.
    var safeForSwiftCode: String {
        guard !isEmpty else {
            return "_empty"
        }

        // Only allow [a-zA-Z][a-zA-Z0-9_]*
        // This is bad, is there something like percent encoding functionality but for general "allowed chars only"?

        let firstCharSet: CharacterSet = .letters
        let numbers: CharacterSet = .decimalDigits
        let otherCharSet: CharacterSet = .alphanumerics.union(.init(charactersIn: "_"))

        var sanitizedScalars: [Unicode.Scalar] = []
        for (index, scalar) in unicodeScalars.enumerated() {
            let allowedSet = index == 0 ? firstCharSet : otherCharSet
            let outScalar: Unicode.Scalar
            if allowedSet.contains(scalar) {
                outScalar = scalar
            } else if index == 0 && numbers.contains(scalar) {
                sanitizedScalars.append("_")
                outScalar = scalar
            } else {
                outScalar = "_"
            }
            sanitizedScalars.append(outScalar)
        }

        let validString = String(UnicodeScalarView(sanitizedScalars))

        guard Self.keywords.contains(validString) else {
            return validString
        }
        return "_\(validString)"
    }

    /// Returns a string sanitized to be usable as a Swift identifier.
    ///
    /// See the proposal SOAR-0001 for details.
    ///
    /// In addition to replacing illegal characters with an underscores, also
    /// ensures that the identifier starts with a letter and not a number.
    var proposedSafeForSwiftCode: String {
        // TODO: New logic proposed in SOAR-0001 goes here.
        return ""
    }

    /// A list of Swift keywords.
    ///
    /// Copied from SwiftSyntax/TokenKind.swift
    private static let keywords: Set<String> = [
        "associatedtype",
        "class",
        "deinit",
        "enum",
        "extension",
        "func",
        "import",
        "init",
        "inout",
        "let",
        "operator",
        "precedencegroup",
        "protocol",
        "struct",
        "subscript",
        "typealias",
        "var",
        "fileprivate",
        "internal",
        "private",
        "public",
        "static",
        "defer",
        "if",
        "guard",
        "do",
        "repeat",
        "else",
        "for",
        "in",
        "while",
        "return",
        "break",
        "continue",
        "fallthrough",
        "switch",
        "case",
        "default",
        "where",
        "catch",
        "throw",
        "as",
        "Any",
        "false",
        "is",
        "nil",
        "rethrows",
        "super",
        "self",
        "Self",
        "true",
        "try",
        "throws",
        "__FILE__",
        "__LINE__",
        "__COLUMN__",
        "__FUNCTION__",
        "__DSO_HANDLE__",
        "_",
        "(",
        ")",
        "{",
        "}",
        "[",
        "]",
        "<",
        ">",
        ".",
        ".",
        ",",
        "...",
        ":",
        ";",
        "=",
        "@",
        "#",
        "&",
        "->",
        "`",
        "\\",
        "!",
        "?",
        "?",
        "\"",
        "\'",
        "\"\"\"",
        "#keyPath",
        "#line",
        "#selector",
        "#file",
        "#fileID",
        "#filePath",
        "#column",
        "#function",
        "#dsohandle",
        "#assert",
        "#sourceLocation",
        "#warning",
        "#error",
        "#if",
        "#else",
        "#elseif",
        "#endif",
        "#available",
        "#unavailable",
        "#fileLiteral",
        "#imageLiteral",
        "#colorLiteral",
        ")",
        "yield",
        "String",
        "Error",
        "Int",
        "Bool",
        "Array",
        "Type",
        "type",
        "Protocol",
        "await",
    ]
}
