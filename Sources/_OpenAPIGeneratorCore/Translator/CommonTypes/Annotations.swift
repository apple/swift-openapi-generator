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
extension VariableDescription {

    /// Returns an expression that suppresses mutability warnings.
    var suppressMutabilityWarningExpr: Expression {
        .identifier("suppressMutabilityWarning")
            .call([
                .init(label: nil, expression: .inOut(.identifier(left)))
            ])
    }
}

extension Declaration {

    /// Returns an expression that suppresses mutability warnings.
    var suppressMutabilityWarningExpr: Expression {
        switch self {
        case .variable(let variableDescription):
            return variableDescription.suppressMutabilityWarningExpr
        default:
            fatalError("Must not request mutability warning expr from non-variable decls")
        }
    }
}

extension Expression {

    /// Returns an expression that suppresses unused variable warnings.
    /// - Parameter name: The name of the variable for which to suppress
    /// the warning.
    static func suppressUnusedWarning(for name: String) -> Self {
        .identifier("suppressUnusedWarning")
            .call([
                .init(label: nil, expression: .identifier(name))
            ])
    }
}
