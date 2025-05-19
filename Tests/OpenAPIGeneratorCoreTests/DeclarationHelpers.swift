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

extension Declaration {
    var commentable: (Comment?, Declaration)? {
        guard case .commentable(let comment, let decl) = self else { return nil }
        return (comment, decl)
    }

    var deprecated: (DeprecationDescription, Declaration)? {
        guard case .deprecated(let description, let decl) = self else { return nil }
        return (description, decl)
    }

    var variable: VariableDescription? {
        guard case .variable(let description) = self else { return nil }
        return description
    }

    var `extension`: ExtensionDescription? {
        guard case .extension(let description) = self else { return nil }
        return description
    }

    var `struct`: StructDescription? {
        guard case .struct(let description) = self else { return nil }
        return description
    }

    var `enum`: EnumDescription? {
        guard case .enum(let description) = self else { return nil }
        return description
    }

    var `typealias`: TypealiasDescription? {
        guard case .typealias(let description) = self else { return nil }
        return description
    }

    var `protocol`: ProtocolDescription? {
        guard case .protocol(let description) = self else { return nil }
        return description
    }

    var function: FunctionDescription? {
        guard case .function(let description) = self else { return nil }
        return description
    }

    var enumCase: EnumCaseDescription? {
        guard case .enumCase(let description) = self else { return nil }
        return description
    }
}
