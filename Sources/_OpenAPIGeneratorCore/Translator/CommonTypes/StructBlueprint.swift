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

/// A structure that contains the information about an OpenAPI object that is
/// required to generate a matching Swift structure.
struct StructBlueprint {

    /// A documentation comment for the structure.
    var comment: Comment?

    /// Whether the type should be annotated as deprecated.
    var isDeprecated: Bool = false

    /// An access modifier.
    var access: AccessModifier?

    /// The type name of the structure.
    var typeName: TypeName

    /// The type names that the structure conforms to.
    var conformances: [String] = []

    /// A Boolean value that indicates whether the generator should include
    /// a coding keys enum for the structure.
    ///
    /// If set to `true`, the coding keys are only generated if there is at least
    /// one property in `properties`, as an empty enum with a raw value
    /// would not compile.
    var shouldGenerateCodingKeys: Bool = false

    /// Describes any customizations to the implementations of Encodable
    /// and Decodable protocols.
    enum OpenAPICodableStrategy {

        /// A standard Codable implementation, methods are synthesized
        /// by the compiler.
        case synthesized

        /// A custom Codable implementation of the decoder only, the encoder
        /// is synthesized by the compiler.
        ///
        /// The decoder contains a call to verify that no undocumented
        /// properties are present.
        case enforcingNoAdditionalProperties

        /// A custom Codable implementation of both the encoder and the decoder.
        ///
        /// Undocumented properties are collected into the extra property
        /// called `additionalProperties`.
        case allowingAdditionalProperties

        /// A Codable implementation for allOf, where all of the child
        /// property types get encoded into the top level keyed container.
        case allOf(propertiesIsKeyValuePairSchema: [Bool])

        /// A Codable implementation for anyOf, where one or more of the child
        /// property types get encoded into the top level keyed container.
        case anyOf(propertiesIsKeyValuePairSchema: [Bool])
    }

    /// The kind of Codable implementation used for the structure.
    ///
    /// The value of this property is ignored if ``shouldGeneratedCodingKeys``
    /// is `false`.
    var codableStrategy: OpenAPICodableStrategy = .synthesized

    /// The properties of the structure.
    var properties: [PropertyBlueprint]
}

extension StructBlueprint {

    /// A Boolean value indicating whether the struct can be initialized using
    /// an empty initializer.
    ///
    /// For example, when all the properties of the struct have a default value,
    /// the struct can be initialized using `Foo()`. This is important for
    /// other types referencing this type.
    var hasEmptyInit: Bool {
        // If at least one property requires an explicit value, this struct
        // cannot have an empty initializer.
        properties.allSatisfy { $0.defaultValue != nil }
    }
}

/// A structure that contains the information about an OpenAPI object property
/// that is required to generate a matching Swift property.
struct PropertyBlueprint {

    /// Describes the default value of a property.
    enum DefaultValue {

        /// A nil literal.
        ///
        /// For example: `init(foo: String? = nil)`
        case `nil`

        /// An empty initializer.
        ///
        /// For example: `init(foo: String = .init())`
        case emptyInit

        /// A custom expression.
        ///
        /// For example: `init(foo: String = "hi")`
        case expression(Expression)
    }

    /// A documentation comment for the property.
    var comment: Comment? = nil

    /// Whether the property should be annotated as deprecated.
    var isDeprecated: Bool = false

    /// The original name of the property specified in the OpenAPI document.
    var originalName: String

    /// The type usage of the property.
    var typeUsage: TypeUsage

    /// A default value for the property.
    var `default`: DefaultValue? = nil

    /// A Boolean value indicating whether this property stores participates
    /// in the Coding implementation of the parent structure.
    ///
    /// Properties defined in the OpenAPI document are serializable, but helper
    /// properties such as `additionalProperties` are not, as there is a custom
    /// Codable implementation that handles those values.
    var isSerializedInTopLevelDictionary: Bool = true

    /// The declarations that should be included right above the
    /// property declaration, used for declaring nested types before
    /// referring to them in the property.
    var associatedDeclarations: [Declaration] = []

    /// A set of configuration values that inform translation.
    var context: TranslatorContext
}

extension PropertyBlueprint {

    /// A name that is verified to be a valid Swift identifier.
    var swiftSafeName: String { context.safeNameGenerator.swiftMemberName(for: originalName) }

    /// The JSON path to the property.
    ///
    /// Nil if the parent JSON path is nil.
    var jsonPath: String? { typeUsage.typeName.fullyQualifiedJSONPath?.appending("/\(originalName)") }

    /// The default value in the initializer.
    ///
    /// Nil if the property is required.
    var defaultValue: DefaultValue? {
        if let explicitDefaultValue = `default` { return explicitDefaultValue }
        guard typeUsage.isOptional else { return nil }
        return .nil
    }
}

extension PropertyBlueprint.DefaultValue {

    /// Returns an expression for the default value.
    var asExpression: Expression {
        switch self {
        case .nil: return .literal(.nil)
        case .emptyInit: return .functionCall(calledExpression: .dot("init"))
        case let .expression(expression): return expression
        }
    }
}
