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
@testable import _OpenAPIGeneratorCore
import Foundation

enum DeclKind: String, Equatable, CustomStringConvertible {
    case deprecated
    case variable
    case `extension`
    case `struct`
    case `enum`
    case `typealias`
    case `protocol`
    case function
    case enumCase

    var description: String { rawValue }
}

struct DeclInfo: Equatable, CustomStringConvertible {
    var name: String? = nil
    var kind: DeclKind

    var description: String {
        let kindDescription = kind.rawValue
        if let name { return "\(kindDescription) (\(name))" }
        return kindDescription
    }
}

enum ExprKind: String, Equatable, CustomStringConvertible {
    case literal
    case identifier
    case memberAccess
    case functionCall
    case assignment
    case `switch`
    case `if`
    case doStatement
    case valueBinding
    case unaryKeyword
    case closureInvocation
    case binaryOperation
    case inOut
    case optionalChaining
    case tuple

    var description: String { rawValue }
}

struct ExprInfo: Equatable, CustomStringConvertible {
    var name: String? = nil
    var kind: ExprKind

    var description: String {
        let kindDescription = kind.rawValue
        if let name { return "\(kindDescription) (\(name))" }
        return kindDescription
    }
}

enum CodeBlockKind: String, Equatable, CustomStringConvertible {
    case declaration
    case expression

    var description: String { rawValue }
}

struct CodeBlockInfo: Equatable, CustomStringConvertible {
    var name: String? = nil
    var kind: CodeBlockKind

    var description: String {
        let kindDescription = kind.rawValue
        if let name { return "\(kindDescription) (\(name))" }
        return kindDescription
    }
}

struct UnexpectedDeclError: Error, CustomStringConvertible, LocalizedError {
    var actual: DeclKind
    var expected: DeclKind

    var description: String { "actual: \(actual), expected: \(expected)" }

    var errorDescription: String? { description }
}

extension Declaration {
    var info: DeclInfo {
        switch strippingTopComment {
        case .deprecated: return .init(kind: .deprecated)
        case let .variable(description):
            return .init(name: TextBasedRenderer.renderedExpressionAsString(description.left), kind: .variable)
        case let .`extension`(description): return .init(name: description.onType, kind: .`extension`)
        case let .`struct`(description): return .init(name: description.name, kind: .`struct`)
        case let .`enum`(description): return .init(name: description.name, kind: .`enum`)
        case let .`typealias`(description): return .init(name: description.name, kind: .`typealias`)
        case let .`protocol`(description): return .init(name: description.name, kind: .`protocol`)
        case let .function(description):
            let name: String
            switch description.signature.kind {
            case .initializer(_): name = "init"
            case .function(name: let _name, _): name = _name
            }
            return .init(name: name, kind: .function)
        case let .enumCase(description): return .init(name: description.name, kind: .enumCase)
        case .commentable: fatalError("Unreachable")
        }
    }
}

extension LiteralDescription {
    var name: String {
        switch self {
        case .string: return "string"
        case .int: return "int"
        case .bool: return "bool"
        case .nil: return "nil"
        case .array: return "array"
        }
    }
}

extension KeywordKind {
    var name: String {
        switch self {
        case .return: return "return"
        case .try(hasPostfixQuestionMark: let hasPostfixQuestionMark): return hasPostfixQuestionMark ? "try?" : "try"
        case .await: return "await"
        case .throw: return "throw"
        case .yield: return "yield"
        }
    }
}

extension BindingKind {
    var name: String {
        switch self {
        case .var: return "var"
        case .let: return "let"
        }
    }
}

extension _OpenAPIGeneratorCore.Expression {
    var info: ExprInfo {
        switch self {
        case .literal(let value): return .init(name: value.name, kind: .literal)
        case .identifier(let value):
            let name: String
            switch value {
            case .pattern(let pattern): name = pattern
            case .type(let type): name = TextBasedRenderer.default.renderedExistingTypeDescription(type)
            }
            return .init(name: name, kind: .identifier)
        case .memberAccess(let value): return .init(name: value.right, kind: .memberAccess)
        case .functionCall(let value): return .init(name: value.calledExpression.info.name, kind: .functionCall)
        case .assignment(let value): return .init(name: value.left.info.name, kind: .assignment)
        case .`switch`(let value): return .init(name: value.switchedExpression.info.name, kind: .switch)
        case .ifStatement(_): return .init(name: nil, kind: .if)
        case .doStatement(_): return .init(name: nil, kind: .doStatement)
        case .valueBinding(let value): return .init(name: value.kind.name, kind: .valueBinding)
        case .unaryKeyword(let value): return .init(name: value.kind.name, kind: .unaryKeyword)
        case .closureInvocation(_): return .init(name: nil, kind: .closureInvocation)
        case .binaryOperation(let value): return .init(name: value.operation.rawValue, kind: .binaryOperation)
        case .inOut(let value): return .init(name: value.referencedExpr.info.name, kind: .inOut)
        case .optionalChaining(let value): return .init(name: value.referencedExpr.info.name, kind: .optionalChaining)
        case .tuple(_): return .init(name: nil, kind: .tuple)
        }
    }
}

extension CodeBlockItem {
    var info: CodeBlockInfo {
        switch self {
        case .declaration(let decl): return .init(name: decl.info.name, kind: .declaration)
        case .expression(let expr): return .init(name: expr.info.name, kind: .expression)
        }
    }
}
