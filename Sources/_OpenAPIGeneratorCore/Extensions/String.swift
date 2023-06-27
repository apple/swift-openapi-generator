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

extension String {

    /// Returns a copy of the string modified to be a valid Swift identifier.
    ///
    /// For sanitization rules, see ``String/sanitizedForSwiftCode``.
    var asSwiftSafeName: String {
        sanitizedForSwiftCode
    }

    /// Returns a copy of the string with the first letter uppercased.
    var uppercasingFirstLetter: String {
        tranformingFirstLetter { $0.uppercased() }
    }

    /// Returns a copy of the string with the first letter lowercased.
    var lowercasingFirstLetter: String {
        tranformingFirstLetter { $0.lowercased() }
    }
}

fileprivate extension Character {

    /// A Boolean value that indicates whether the character is an underscore.
    var isUnderscore: Bool { self == "_" }
}

fileprivate extension String {

    /// Returns a copy of the string with the first letter modified by
    /// the specified closure.
    /// - Parameter transformation: A closure that modifies the first letter.
    func tranformingFirstLetter<T>(_ transformation: (Character) -> T) -> String where T: StringProtocol {
        guard let firstLetterIndex = self.firstIndex(where: \.isLetter) else {
            return self
        }
        return self.replacingCharacters(
            in: firstLetterIndex..<self.index(after: firstLetterIndex),
            with: transformation(self[firstLetterIndex])
        )
    }

    /// Returns a string sanitized to be usable as a Swift identifier.
    ///
    /// For example, the string `$nake…` would be returned as `_dollar_nake_x2026_`, because
    /// both the dollar and ellipsis sign are not valid characters in a Swift identifier.
    /// So, it replaces such characters with their html enity equivalents or unicode hex representation,
    /// in case its not present in the `specialCharsMap`. It marks this replacement with `_` as a delimiter.
    ///
    /// In addition to replacing illegal characters, it also
    /// ensures that the identifier starts with a letter and not a number.
    var sanitizedForSwiftCode: String {
        guard !isEmpty else {
            return "_empty"
        }

        let firstCharSet: CharacterSet = .letters.union(.init(charactersIn: "_"))
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
                sanitizedScalars.append("_")
                if let entityName = Self.specialCharsMap[scalar] {
                    for char in entityName.unicodeScalars {
                        sanitizedScalars.append(char)
                    }
                } else {
                    sanitizedScalars.append("x")
                    let hexString = String(scalar.value, radix: 16, uppercase: true)
                    for char in hexString.unicodeScalars {
                        sanitizedScalars.append(char)
                    }
                }
                sanitizedScalars.append("_")
                continue
            }
            sanitizedScalars.append(outScalar)
        }

        let validString = String(UnicodeScalarView(sanitizedScalars))

        //Special case for a single underscore.
        //We can't add it to the map as its a valid swift identifier in other cases.
        if validString == "_" {
            return "_underscore_"
        }

        guard Self.keywords.contains(validString) else {
            return validString
        }
        return "_\(validString)"
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
    
    /// A map of ASCII printable characters to their HTML entity names.
    private static let specialCharsMap: [Unicode.Scalar: String] = [
        " ": "space",
        "!": "excl",
        "\"": "quot",
        "#": "num",
        "$": "dollar",
        "%": "percnt",
        "&": "amp",
        "'": "apos",
        "(": "lpar",
        ")": "rpar",
        "*": "ast",
        "+": "plus",
        ",": "comma",
        "-": "hyphen",
        ".": "period",
        "/": "sol",
        ":": "colon",
        ";": "semi",
        "<": "lt",
        "=": "equals",
        ">": "gt",
        "?": "quest",
        "@": "commat",
        "[": "lbrack",
        "\\": "bsol",
        "]": "rbrack",
        "^": "hat",
        "`": "grave",
        "{": "lcub",
        "|": "verbar",
        "}": "rcub",
        "~": "tilde",
    ]
}
