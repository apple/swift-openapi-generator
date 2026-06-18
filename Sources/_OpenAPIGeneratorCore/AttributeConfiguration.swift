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

/// Configuration for Swift attributes to add to generated API protocol declarations.
public struct AttributeConfiguration: Sendable, Equatable, Codable {

    /// Attributes applied to the generated `APIProtocol` declaration.
    public var protocolAttributes: [AttributeDescription]

    /// Attributes applied to each method requirement in `APIProtocol`.
    public var methodAttributes: [AttributeDescription]

    /// The default attribute configuration, with no attributes.
    public static let `default`: Self = .init()

    enum CodingKeys: String, CodingKey {
        case protocolAttributes = "protocol"
        case methodAttributes = "methods"
    }

    /// Creates an attribute configuration.
    /// - Parameters:
    ///   - protocolAttributes: Attributes applied to the generated `APIProtocol` declaration.
    ///   - methodAttributes: Attributes applied to each method requirement in `APIProtocol`.
    public init(protocolAttributes: [AttributeDescription] = [], methodAttributes: [AttributeDescription] = []) {
        self.protocolAttributes = protocolAttributes
        self.methodAttributes = methodAttributes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.protocolAttributes =
            try container.decodeIfPresent([AttributeDescription].self, forKey: .protocolAttributes) ?? []
        self.methodAttributes = try container.decodeIfPresent([AttributeDescription].self, forKey: .methodAttributes) ?? []
    }
}
