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

struct SwiftNameOptions: OptionSet {
    let rawValue: Int32
    
    static let none = SwiftNameOptions([])
    
    static let capitalize = SwiftNameOptions(rawValue: 1 << 0)
    
    static let all: SwiftNameOptions = [.capitalize]
}

extension String {

    /// Returns a string sanitized to be usable as a Swift identifier.
    ///
    /// See the proposal SOAR-0001 for details.
    ///
    /// For example, the string `$nake…` would be returned as `_dollar_nake_x2026_`, because
    /// both the dollar and ellipsis sign are not valid characters in a Swift identifier.
    /// So, it replaces such characters with their html entity equivalents or unicode hex representation,
    /// in case it's not present in the `specialCharsMap`. It marks this replacement with `_` as a delimiter.
    ///
    /// In addition to replacing illegal characters, it also
    /// ensures that the identifier starts with a letter and not a number.
    func safeForSwiftCode_defensive(options: SwiftNameOptions) -> String {        
        guard !isEmpty else { return "_empty" }

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
                    for char in entityName.unicodeScalars { sanitizedScalars.append(char) }
                } else {
                    sanitizedScalars.append("x")
                    let hexString = String(scalar.value, radix: 16, uppercase: true)
                    for char in hexString.unicodeScalars { sanitizedScalars.append(char) }
                }
                sanitizedScalars.append("_")
                continue
            }
            sanitizedScalars.append(outScalar)
        }

        let validString = String(UnicodeScalarView(sanitizedScalars))

        //Special case for a single underscore.
        //We can't add it to the map as its a valid swift identifier in other cases.
        if validString == "_" { return "_underscore_" }

        guard Self.keywords.contains(validString) else { return validString }
        return "_\(validString)"
    }

    /// Returns a string sanitized to be usable as a Swift identifier, and tries to produce UpperCamelCase
    /// or lowerCamelCase string, the casing is controlled using the provided options.
    ///
    /// If the string contains any illegal characters, falls back to the behavior
    /// matching `safeForSwiftCode_defensive`.
    func safeForSwiftCode_idiomatic(options: SwiftNameOptions) -> String {
        let capitalize = options.contains(.capitalize)
        if isEmpty {
            return capitalize ? "_Empty_" : "_empty_"
        }
        
        // Detect cases like HELLO_WORLD, sometimes used for constants.
        let isAllUppercase = allSatisfy {
            // Must check that no characters are lowercased, as non-letter characters
            // don't return `true` to `isUppercase`.
            !$0.isLowercase
        }

        // 1. Leave leading underscores as-are
        // 2. In the middle: word separators: ["_", "-", <space>] -> remove and capitalize next word
        // 3. In the middle: period: [".", "/"] -> replace with "_"
        // 4. In the middle: drop ["{", "}"] -> replace with ""
        
        var buffer: [Character] = []
        buffer.reserveCapacity(count)
        
        enum State {
            case modifying
            case fallback
            case preFirstWord
            case accumulatingWord
            case waitingForWordStarter
        }
        var state: State = .preFirstWord
        for char in self {
            let _state = state
            state = .modifying
            switch _state {
            case .preFirstWord:
                if char == "_" {
                    // Leading underscores are kept.
                    buffer.append(char)
                    state = .preFirstWord
                } else if char.isNumber {
                    // Prefix with an underscore if the first character is a number.
                    buffer.append("_")
                    buffer.append(char)
                    state = .accumulatingWord
                } else if char.isLetter {
                    // First character in the identifier.
                    buffer.append(contentsOf: capitalize ? char.uppercased() : char.lowercased())
                    state = .accumulatingWord
                } else {
                    // Illegal character, fall back to the defensive strategy.
                    state = .fallback
                }
            case .accumulatingWord:
                if char.isLetter || char.isNumber {
                    if isAllUppercase {
                        buffer.append(contentsOf: char.lowercased())
                    } else {
                        buffer.append(char)
                    }
                    state = .accumulatingWord
                } else if ["_", "-", " "].contains(char) {
                    // In the middle of an identifier, dashes, underscores, and spaces are considered
                    // word separators, so we remove the character and end the current word.
                    state = .waitingForWordStarter
                } else if [".", "/"].contains(char) {
                    // In the middle of an identifier, a period or a slash gets replaced with
                    // an underscore, but continues the current word.
                    buffer.append("_")
                    state = .accumulatingWord
                } else if ["{", "}"].contains(char) {
                    // In the middle of an identifier, curly braces are dropped.
                    state = .accumulatingWord
                } else {
                    // Illegal character, fall back to the defensive strategy.
                    state = .fallback
                }
            case .waitingForWordStarter:
                if ["_", "-", ".", "/", "{", "}"].contains(char) {
                    // Between words, just drop allowed special characters, since
                    // we're already between words anyway.
                    state = .waitingForWordStarter
                } else if char.isLetter || char.isNumber {
                    // Starting a new word in the middle of the identifier.
                    buffer.append(contentsOf: char.uppercased())
                    state = .accumulatingWord
                } else {
                    // Illegal character, fall back to the defensive strategy.
                    state = .fallback
                }
            case .modifying, .fallback:
                preconditionFailure("Logic error in \(#function), string: '\(self)'")
            }
            precondition(state != .modifying, "Logic error in \(#function), string: '\(self)'")
            if case .fallback = state {
                return safeForSwiftCode_defensive(options: options)
            }
        }
        if buffer.isEmpty || state == .preFirstWord {
            return safeForSwiftCode_defensive(options: options)
        }
        // Check for keywords
        let newString = String(buffer)
        if Self.keywords.contains(newString) {
            return "_\(newString)"
        }
        return newString
    }

    /// A list of Swift keywords.
    ///
    /// Copied from SwiftSyntax/TokenKind.swift
    private static let keywords: Set<String> = [
        "associatedtype", "class", "deinit", "enum", "extension", "func", "import", "init", "inout", "let", "operator",
        "precedencegroup", "protocol", "struct", "subscript", "typealias", "var", "fileprivate", "internal", "private",
        "public", "static", "defer", "if", "guard", "do", "repeat", "else", "for", "in", "while", "return", "break",
        "continue", "fallthrough", "switch", "case", "default", "where", "catch", "throw", "as", "Any", "false", "is",
        "nil", "rethrows", "super", "self", "Self", "true", "try", "throws", "yield", "String", "Error", "Int", "Bool",
        "Array", "Type", "type", "Protocol", "await",
    ]

    /// A map of ASCII printable characters to their HTML entity names. Used to reduce collisions in generated names.
    private static let specialCharsMap: [Unicode.Scalar: String] = [
        " ": "space", "!": "excl", "\"": "quot", "#": "num", "$": "dollar", "%": "percnt", "&": "amp", "'": "apos",
        "(": "lpar", ")": "rpar", "*": "ast", "+": "plus", ",": "comma", "-": "hyphen", ".": "period", "/": "sol",
        ":": "colon", ";": "semi", "<": "lt", "=": "equals", ">": "gt", "?": "quest", "@": "commat", "[": "lbrack",
        "\\": "bsol", "]": "rbrack", "^": "hat", "`": "grave", "{": "lcub", "|": "verbar", "}": "rcub", "~": "tilde",
    ]
}
