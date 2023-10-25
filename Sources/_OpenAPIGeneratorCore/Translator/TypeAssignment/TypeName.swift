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

/// A fully-qualified type name that contains the components of both the Swift
/// type name and the optional JSON reference.
///
/// Use the type name to define a type, see also `TypeUsage` when referring
/// to a type.
struct TypeName: Hashable {

    /// Describes a single component of both the Swift and JSON  paths.
    ///
    /// At least one of the properties is always specified, possibly both.
    ///
    /// This type preserves the information about which Swift path component
    /// maps to which JSON path component, and vice versa, and allows
    /// reliably adding and removing extra path components.
    struct Component: Hashable {

        /// The name of the Swift path component.
        var swift: String?

        /// The name of the JSON path component.
        var json: String?
    }

    /// A list of components that make up the type name.
    private let components: [Component]

    /// The list of Swift path components.
    var swiftKeyPathComponents: [String] { components.compactMap(\.swift) }

    /// The list of JSON path components.
    ///
    /// Returns nil when the type name has no JSON path components.
    private var jsonKeyPathComponents: [String]? {
        let jsonComponents = components.compactMap(\.json)
        guard !jsonComponents.isEmpty else { return nil }
        return jsonComponents
    }

    /// Creates a new type name with the specified list of components.
    /// - Parameter components: A list of components for the type.
    init(components: [Component]) {
        precondition(!components.compactMap(\.swift).isEmpty, "TypeName Swift key path cannot be empty")
        self.components = components
    }

    /// Creates a new type name with the specified list of Swift path
    /// components.
    ///
    /// Use this initializer when the type name has no JSON path components.
    /// - Parameter swiftKeyPath: A list of Swift path components for the type.
    init(swiftKeyPath: [String]) {
        precondition(!swiftKeyPath.isEmpty, "TypeName Swift key path cannot be empty")
        self.init(components: swiftKeyPath.map { .init(swift: $0, json: nil) })
    }

    /// A string representation of the fully qualified Swift type name.
    ///
    /// For example: `Swift.Int`.
    var fullyQualifiedSwiftName: String { swiftKeyPathComponents.joined(separator: ".") }

    /// A string representation of the last path component of the Swift
    /// type name.
    ///
    /// For example: `Int`.
    var shortSwiftName: String { swiftKeyPathComponents.last! }

    /// A string representation of the fully qualified JSON path.
    ///
    /// For example: `#/components/schemas/Foo`.
    /// - Returns: A string representation; nil if the type name has no
    /// JSON path components or if the last JSON path component is nil.
    var fullyQualifiedJSONPath: String? {
        guard components.last?.json != nil else { return nil }
        return jsonKeyPathComponents?.joined(separator: "/")
    }

    /// A string representation of the last path component of the JSON path.
    ///
    /// For example: `Foo`.
    /// - Returns: A string representation; nil if the type name has no
    /// JSON path components.
    var shortJSONName: String? { jsonKeyPathComponents?.last }

    /// Returns a type name by appending the specified components to the
    /// current type name.
    ///
    /// In other words, returns a type name for a child type.
    /// - Precondition: At least one of the components must be non-nil.
    /// - Parameters:
    ///   - swiftComponent: The name of the Swift type component.
    ///   - jsonComponent: The name of the JSON path component.
    /// - Returns: A new type name.
    func appending(swiftComponent: String? = nil, jsonComponent: String? = nil) -> Self {
        precondition(swiftComponent != nil || jsonComponent != nil, "At least the Swift or JSON name must be non-nil.")
        let newComponent = Component(swift: swiftComponent, json: jsonComponent)
        return .init(components: components + [newComponent])
    }

    /// Returns a type name by removing the last component from the current
    /// type name.
    ///
    /// In other words, returns a type name for the parent type.
    var parent: TypeName {
        precondition(components.count >= 1, "Cannot get the parent of a root type")
        return .init(components: components.dropLast())
    }
}

extension TypeName: CustomStringConvertible {
    var description: String {
        if let fullyQualifiedJSONPath { return "\(fullyQualifiedSwiftName) (\(fullyQualifiedJSONPath))" }
        return fullyQualifiedSwiftName
    }
}

extension TypeName.Component {

    /// The type name component for the root type, which all other types
    /// are child types of.
    ///
    /// Has a nil Swift component and the JSON path component `#`.
    static var root: Self { .init(swift: nil, json: "#") }
}
