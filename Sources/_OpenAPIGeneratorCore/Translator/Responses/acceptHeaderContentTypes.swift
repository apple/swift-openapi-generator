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
import OpenAPIKit30
import Algorithms

extension FileTranslator {

    /// Returns a list of candidate content-types from all responses in
    /// the specified operation.
    ///
    /// - Parameter description: The OpenAPI operation.
    /// - Returns: A list of content types. Might be empty, in which case no
    /// Accept header should be sent in the request.
    func acceptHeaderContentTypes(
        for description: OperationDescription
    ) throws -> [ContentType] {
        let contentTypes =
            try description
            .operation
            .responseOutcomes
            .compactMap { outcome in
                let response = try outcome.response.resolve(in: components)
                return bestSingleContent(
                    response.content,
                    foundIn: description.operationID
                )
            }
            .map { content in
                content.contentType
            }
        return Array(contentTypes.uniqued())
    }
}
