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
import OpenAPIKit

extension FileTranslator {

    /// Returns a declaration of a typealias.
    /// - Parameters:
    ///   - typeName: The name of the type to give to the declared typealias.
    ///   - userDescription: A user-specified description from the OpenAPI document.
    ///   - existingTypeUsage: The existing type the alias points to.
    /// - Throws: An error if there is an issue during translation.
    /// - Returns: A declaration representing the translated typealias.
    func translateTypealias(named typeName: TypeName, userDescription: String?, to existingTypeUsage: TypeUsage) throws
        -> Declaration
    {
        let typealiasDescription = TypealiasDescription(
            accessModifier: config.access,
            name: typeName.shortSwiftName,
            existingType: .init(existingTypeUsage.withOptional(false))
        )
        let typealiasComment: Comment? = typeName.docCommentWithUserDescription(userDescription)
        return .commentable(typealiasComment, .typealias(typealiasDescription))
    }
}
