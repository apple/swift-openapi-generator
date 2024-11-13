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
    func safeForSwiftCode_optimistic(options: SwiftNameOptions) -> String {
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
        // 3. In the middle: period: ["."] -> replace with "_"
        
        var buffer: [Character] = []
        buffer.reserveCapacity(count)
        
        enum State {
            case modifying
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
                    return safeForSwiftCode_defensive(options: options)
                }
            case .accumulatingWord:
                if char.isLetter || char.isNumber {
                    if isAllUppercase {
                        buffer.append(contentsOf: char.lowercased())
                    } else {
                        buffer.append(char)
                    }
                    state = .accumulatingWord
                } else if char == "_" || char == "-" || char == " " {
                    // In the middle of an identifier, dashes, underscores, and spaces are considered
                    // word separators, so we remove the character and end the current word.
                    state = .waitingForWordStarter
                } else if char == "." {
                    // In the middle of an identifier, a period gets replaced with an underscore, but continues
                    // the current word.
                    buffer.append("_")
                    state = .accumulatingWord
                } else {
                    // Illegal character, fall back to the defensive strategy.
                    return safeForSwiftCode_defensive(options: options)
                }
            case .waitingForWordStarter:
                if char == "_" || char == "-" {
                    // Between words, just drop dashes, underscores, and spaces, since
                    // we're already between words anyway.
                    state = .waitingForWordStarter
                } else if char.isLetter || char.isNumber {
                    // Starting a new word in the middle of the identifier.
                    buffer.append(contentsOf: char.uppercased())
                    state = .accumulatingWord
                } else {
                    // Illegal character, fall back to the defensive strategy.
                    return safeForSwiftCode_defensive(options: options)
                }
            case .modifying:
                preconditionFailure("Logic error in \(#function), string: '\(self)'")
            }
            precondition(state != .modifying, "Logic error in \(#function), string: '\(self)'")
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

    private static let identifierHeadCharactersRanges: [ClosedRange<Character>] = {
        // https://docs.swift.org/swift-book/documentation/the-swift-programming-language/lexicalstructure/#Identifiers
        var ranges: [ClosedRange<Character>] = []
        // identifier-head → Upper- or lowercase letter A through Z
        ranges.append("A"..."Z")
        ranges.append("a"..."z")
        // identifier-head → _
        ranges.append("_")
        // identifier-head → U+00A8, U+00AA, U+00AD, U+00AF, U+00B2–U+00B5, or U+00B7–U+00BA
        ranges.appendFromSet([0x00A8, 0x00AA, 0x00AD, 0x00AF])
        ranges.appendFromScalars(0x00B2...0x00B5)
        ranges.appendFromScalars(0x00B7...0x00BA)
        // identifier-head → U+00BC–U+00BE, U+00C0–U+00D6, U+00D8–U+00F6, or U+00F8–U+00FF
        ranges.appendFromScalars(0x00BC...0x00BE)
        ranges.appendFromScalars(0x00C0...0x00D6)
        ranges.appendFromScalars(0x00D8...0x00F6)
        ranges.appendFromScalars(0x00F8...0x00FF)
        // identifier-head → U+0100–U+02FF, U+0370–U+167F, U+1681–U+180D, or U+180F–U+1DBF
        ranges.appendFromScalars(0x0100...0x02FF)
        ranges.appendFromScalars(0x0370...0x167F)
        ranges.appendFromScalars(0x1681...0x180D)
        ranges.appendFromScalars(0x180F...0x1DBF)
        // identifier-head → U+1E00–U+1FFF
        ranges.appendFromScalars(0x1E00...0x1FFF)
        // identifier-head → U+200B–U+200D, U+202A–U+202E, U+203F–U+2040, U+2054, or U+2060–U+206F
        ranges.appendFromScalars(0x200B...0x200D)
        ranges.appendFromScalars(0x202A...0x202E)
        ranges.appendFromScalars(0x203F...0x2040)
        ranges.appendFromScalar(0x2054)
        ranges.appendFromScalars(0x2060...0x206F)
        // identifier-head → U+2070–U+20CF, U+2100–U+218F, U+2460–U+24FF, or U+2776–U+2793
        ranges.appendFromScalars(0x2070...0x20CF)
        ranges.appendFromScalars(0x2100...0x218F)
        ranges.appendFromScalars(0x2460...0x24FF)
        ranges.appendFromScalars(0x2776...0x2793)
        // identifier-head → U+2C00–U+2DFF or U+2E80–U+2FFF
        ranges.appendFromScalars(0x2C00...0x2DFF)
        ranges.appendFromScalars(0x2E80...0x2FFF)
        // identifier-head → U+3004–U+3007, U+3021–U+302F, U+3031–U+303F, or U+3040–U+D7FF
        ranges.appendFromScalars(0x3004...0x3007)
        ranges.appendFromScalars(0x3021...0x302F)
        ranges.appendFromScalars(0x3031...0x303F)
        ranges.appendFromScalars(0x3040...0xD7FF)
        // identifier-head → U+F900–U+FD3D, U+FD40–U+FDCF, U+FDF0–U+FE1F, or U+FE30–U+FE44
        ranges.appendFromScalars(0xF900...0xFD3D)
        ranges.appendFromScalars(0xFD40...0xFDCF)
        ranges.appendFromScalars(0xFDF0...0xFE1F)
        ranges.appendFromScalars(0xFE30...0xFE44)
        // identifier-head → U+FE47–U+FFFD
        ranges.appendFromScalars(0xFE47...0xFFFD)
        // identifier-head → U+10000–U+1FFFD, U+20000–U+2FFFD, U+30000–U+3FFFD, or U+40000–U+4FFFD
        ranges.appendFromScalars(0x10000...0x1FFFD)
        ranges.appendFromScalars(0x20000...0x2FFFD)
        ranges.appendFromScalars(0x30000...0x3FFFD)
        ranges.appendFromScalars(0x40000...0x4FFFD)
        // identifier-head → U+50000–U+5FFFD, U+60000–U+6FFFD, U+70000–U+7FFFD, or U+80000–U+8FFFD
        ranges.appendFromScalars(0x50000...0x5FFFD)
        ranges.appendFromScalars(0x60000...0x6FFFD)
        ranges.appendFromScalars(0x70000...0x7FFFD)
        ranges.appendFromScalars(0x80000...0x8FFFD)
        // identifier-head → U+90000–U+9FFFD, U+A0000–U+AFFFD, U+B0000–U+BFFFD, or U+C0000–U+CFFFD
        ranges.appendFromScalars(0x90000...0x9FFFD)
        ranges.appendFromScalars(0xA0000...0xAFFFD)
        ranges.appendFromScalars(0xB0000...0xBFFFD)
        ranges.appendFromScalars(0xC0000...0xCFFFD)
        // identifier-head → U+D0000–U+DFFFD or U+E0000–U+EFFFD
        ranges.appendFromScalars(0xD0000...0xDFFFD)
        ranges.appendFromScalars(0xE0000...0xEFFFD)
        return ranges
    }()

    private static let identifierNonHeadCharactersRanges: [ClosedRange<Character>] = {
        var ranges: [ClosedRange<Character>] = []
        // identifier-character → Digit 0 through 9
        ranges.append("0"..."9")
        // identifier-character → U+0300–U+036F, U+1DC0–U+1DFF, U+20D0–U+20FF, or U+FE20–U+FE2F
        ranges.appendFromScalars(0x0300...0x036F)
        ranges.appendFromScalars(0x1DC0...0x1DFF)
        ranges.appendFromScalars(0x20D0...0x20FF)
        ranges.appendFromScalars(0xFE20...0xFE2F)
        return ranges
    }()

    private static let identifierCharactersRanges: [ClosedRange<Character>] = {
        var ranges: [ClosedRange<Character>] = []
        ranges.append(contentsOf: identifierHeadCharactersRanges)
        ranges.append(contentsOf: identifierNonHeadCharactersRanges)
        return ranges
    }()

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

extension [ClosedRange<Character>] {
    func contains(_ char: Character) -> Bool {
        // TODO: This could be optimized if we create a data structure of sorted ranges and use binary search.
        for range in self {
            if range.contains(char) {
                return true
            }
        }
        return false
    }
    
    mutating func appendFromScalar(_ scalar: Int) {
        append(Character(UnicodeScalar(scalar)!)...Character(UnicodeScalar(scalar)!))
    }

    mutating func appendFromSet(_ set: Set<Int>) {
        append(contentsOf: ClosedRange<Character>.fromSet(set))
    }
    
    mutating func appendFromScalars(_ range: ClosedRange<Int>) {
        append(Character(UnicodeScalar(range.lowerBound)!)...Character(UnicodeScalar(range.upperBound)!))
    }
}

extension ClosedRange: @retroactive ExpressibleByUnicodeScalarLiteral where Bound == Character {
    public typealias UnicodeScalarLiteralType = Character
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        let char = Character(unicodeScalarLiteral: value)
        self = char...char
    }
}

extension ClosedRange where Bound == Character {
    static func fromSet(_ set: Set<Int>) -> [Self] {
        set.map {
            Character(UnicodeScalar($0)!)...Character(UnicodeScalar($0)!)
        }
    }
}

fileprivate extension Set where Element == Character {
    mutating func insert(charactersInString string: String) {
        for character in string {
            insert(character)
        }
    }
    
    mutating func insert(allFrom lowerBound: Character, upTo upperBound: Character) {
        for byte in lowerBound.asciiValue!...upperBound.asciiValue! {
            insert(Character(UnicodeScalar(byte)))
        }
    }
    
    mutating func insert(scalarWithCode code: Int) {
        insert(Character(UnicodeScalar(code)!))
    }
    
    mutating func insert(scalarInSet set: Set<Int>) {
        for code in set {
            insert(scalarWithCode: code)
        }
    }
    
    mutating func insert(scalarsInRangeFrom lowerBound: Int, upTo upperBound: Int) {
        for code in lowerBound...upperBound {
            insert(scalarWithCode: code)
        }
    }
}

@available(*, deprecated)
fileprivate extension UInt8 {

    var isUppercaseLetter: Bool {
        (0x41...0x5a).contains(self)
    }

    var isLowercaseLetter: Bool {
        (0x61...0x7a).contains(self)
    }

    var isLetter: Bool {
        isUppercaseLetter || isLowercaseLetter
    }

    var isNumber: Bool {
        (0x30...0x39).contains(self)
    }

    var isLowercaseLetterOrNumber: Bool {
        isLowercaseLetter || isNumber
    }

    var isAlphanumeric: Bool {
        isLetter || isNumber
    }

    var asUppercase: UInt8 {
        if isUppercaseLetter || isNumber {
            return self
        }
        if isLowercaseLetter {
            return self - 0x20
        }
        preconditionFailure("Cannot uppercase not a letter or number")
    }

    var asLowercase: UInt8 {
        if isLowercaseLetter || isNumber {
            return self
        }
        if isUppercaseLetter {
            return self + 0x20
        }
        preconditionFailure("Cannot lowercase not a letter or number")
    }
    
    var isWordSeparator: Bool {
        self == 0x2d /* - */ || self == 0x5f /* _ */
    }
}
