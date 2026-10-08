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

extension TypesFileTranslator {

    /// Finds and boxes types that participate in recursion.
    ///
    /// For a conceptual overview, see the article `Supporting recursive types`.
    /// - Parameter decls: Declarations of `Components.Schemas.*` types.
    /// - Returns: All the declarations, with the types that participate in
    ///   recursion with boxed internal storage.
    /// - Throws: If an unsupported reference cycle is detected.
    func boxRecursiveTypes(_ decls: [Declaration]) throws -> [Declaration] {

        let nodes = decls.compactMap(DeclarationRecursionDetector.Node.init)
        let nodeLookup = Dictionary(nodes.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        let container = DeclarationRecursionDetector.Container(lookupMap: nodeLookup)

        let recursiveNames = try RecursionDetector.computeBoxedTypes(rootNodes: nodes, container: container)
        var boxedNames = recursiveNames

        var decls = decls
        if let maxInlineSchemaSize = config.maxInlineSchemaSize {
            var estimator = InlineSizeEstimator(
                schemaDecls: decls,
                alreadyBoxed: boxedNames,
                maxInlineSize: maxInlineSchemaSize
            )
            estimator.run()
            boxedNames = estimator.boxedSchemaNames
            if !estimator.boxedNestedTypes.isEmpty {
                decls = decls.map {
                    boxingNestedTypes(
                        $0,
                        parent: Constants.Components.Schemas.components,
                        paths: estimator.boxedNestedTypes,
                        isTopLevel: true
                    )
                }
            }
        }
        for (index, decl) in decls.enumerated() {
            guard let name = decl.name, boxedNames.contains(name) else { continue }
            if recursiveNames.contains(name) {
                try diagnostics.emit(
                    .note(
                        message: "Detected a recursive type; it will be boxed to break the reference cycle.",
                        context: ["name": name]
                    )
                )
            }
            decls[index] = boxedType(decl)
        }
        return decls
    }

    /// Boxes the nested types at the provided fully qualified paths.
    /// - Parameters:
    ///   - decl: The declaration to search.
    ///   - parent: The fully qualified name components of the enclosing type.
    ///   - paths: The fully qualified name components of the nested types to box.
    ///   - isTopLevel: Whether the declaration is a top-level schema, which is boxed separately.
    /// - Returns: The declaration with the matching nested types boxed.
    private func boxingNestedTypes(_ decl: Declaration, parent: [String], paths: Set<[String]>, isTopLevel: Bool)
        -> Declaration
    {
        switch decl {
        case .commentable(let comment, let declaration):
            return .commentable(
                comment,
                boxingNestedTypes(declaration, parent: parent, paths: paths, isTopLevel: isTopLevel)
            )
        case .deprecated(let deprecation, let declaration):
            return .deprecated(
                deprecation,
                boxingNestedTypes(declaration, parent: parent, paths: paths, isTopLevel: isTopLevel)
            )
        case .struct(var desc):
            let path = parent + [desc.name]
            desc.members = desc.members.map { boxingNestedTypes($0, parent: path, paths: paths, isTopLevel: false) }
            if !isTopLevel, paths.contains(path) { desc = boxedStruct(desc, qualifiedName: path) }
            return .struct(desc)
        case .enum(var desc):
            let path = parent + [desc.name]
            desc.members = desc.members.map { boxingNestedTypes($0, parent: path, paths: paths, isTopLevel: false) }
            if !isTopLevel, paths.contains(path) { desc = boxedEnum(desc) }
            return .enum(desc)
        case .variable, .extension, .typealias, .protocol, .function, .enumCase: return decl
        }
    }

    /// Boxes the provided declaration, given that the concrete declaration
    /// kind supports boxing.
    /// - Parameter decl: A declaration to be boxed.
    /// - Returns: A boxed variant of the provided declaration.
    private func boxedType(_ decl: Declaration) -> Declaration {
        switch decl {
        case .commentable(let comment, let declaration): return .commentable(comment, boxedType(declaration))
        case .deprecated(let deprecationDescription, let declaration):
            return .deprecated(deprecationDescription, boxedType(declaration))
        case .struct(let structDescription): return .struct(boxedStruct(structDescription))
        case .enum(let enumDescription): return .enum(boxedEnum(enumDescription))
        case .variable, .extension, .typealias, .protocol, .function, .enumCase:
            preconditionFailure("Unexpected boxed type: \(decl.name ?? "<nil>")")
        }
    }

    /// Boxes the provided struct description.
    /// - Parameters:
    ///   - desc: The struct description to box.
    ///   - qualifiedName: The fully qualified name components of the struct, if it is not a top-level schema.
    /// - Returns: A boxed variant of the provided struct description.
    private func boxedStruct(_ desc: StructDescription, qualifiedName: [String]? = nil) -> StructDescription {

        // Start with a copy of the public struct, then modify it.
        var storageDesc = desc

        storageDesc.name = "Storage"
        storageDesc.accessModifier = .private

        // Remove the explicit initializer's comment.
        storageDesc.members = storageDesc.members.map { member in
            guard case .function(let funcDesc) = member.strippingTopComment,
                funcDesc.signature.kind == .initializer(failable: false),
                funcDesc.signature.parameters.first?.name != "decoder"
            else { return member }
            return member.strippingTopComment
        }

        // Make all members internal by removing the explicit access modifier.
        storageDesc.members = storageDesc.members.map { member in
            var member = member
            member.accessModifier = nil
            return member
        }

        // Change CodingKeys, if present, into a typealias to the outer struct.
        storageDesc.members = storageDesc.members.map { member in
            guard case .enum(let enumDescription) = member, enumDescription.name == Constants.Codable.codingKeysName
            else { return member }
            return .typealias(
                name: Constants.Codable.codingKeysName,
                existingType: .member(
                    (qualifiedName ?? Constants.Components.Schemas.components + [desc.name]) + [
                        Constants.Codable.codingKeysName
                    ]
                )
            )
        }

        // Drop the nested type declarations: stored properties refer to the outer struct's copies by
        // their fully qualified names, so the copies in the storage would only be dead duplicates.
        storageDesc.members = storageDesc.members.filter { member in
            switch member.strippingTopComment {
            case .struct, .enum: return false
            case .deprecated(_, .struct), .deprecated(_, .enum): return false
            default: return true
            }
        }

        var desc = desc

        // Define explicit setters/getters for properties and call into storage.
        desc.members = desc.members.map { member in
            guard case .commentable(let comment, let commented) = member,
                case .variable(var variableDescription) = commented
            else { return member }
            let name = TextBasedRenderer.renderedExpressionAsString(variableDescription.left)
            variableDescription.getter = [.expression(.selfDot("storage").dot("value").dot(name))]
            variableDescription.modify = [.expression(.yield(.inOut(.selfDot("storage").dot("value").dot(name))))]
            return .commentable(comment, .variable(variableDescription))
        }

        // Change the initializer to call into storage instead.
        desc.members = desc.members.map { member in
            guard case .commentable(let comment, let commented) = member, case .function(var funcDesc) = commented,
                funcDesc.signature.kind == .initializer(failable: false),
                funcDesc.signature.parameters.first?.name != "decoder"
            else { return member }
            let propertyNames: [String] = desc.members.compactMap { member in
                guard case .variable(let variableDescription) = member.strippingTopComment else { return nil }
                return TextBasedRenderer.renderedExpressionAsString(variableDescription.left)
            }
            funcDesc.body = [
                .expression(
                    .assignment(
                        left: .selfDot("storage"),
                        right: .dot("init")
                            .call([
                                .init(
                                    label: "value",
                                    expression: .dot("init")
                                        .call(
                                            propertyNames.map { .init(label: $0, expression: .identifierPattern($0)) }
                                        )
                                )
                            ])
                    )
                )
            ]
            return .commentable(comment, .function(funcDesc))
        }

        // Define a custom encoder/decoder to call into storage.
        // First remove any existing ones, then add the new ones.
        desc.members = desc.members.filter { member in
            guard case .function(let funcDesc) = member, funcDesc.signature.kind == .initializer(failable: false),
                funcDesc.signature.parameters.first?.name == "decoder"
            else { return true }
            return false
        }
        desc.members = desc.members.filter { member in
            guard case .function(let funcDesc) = member,
                funcDesc.signature.kind == .function(name: "encode", isStatic: false)
            else { return true }
            return false
        }
        desc.members.append(
            .function(
                accessModifier: desc.accessModifier,
                kind: .initializer(failable: false),
                parameters: [.init(label: "from", name: "decoder", type: .any(.member(["Swift", "Decoder"])))],
                keywords: [.throws],
                body: [
                    .expression(
                        .assignment(
                            left: .selfDot("storage"),
                            right: .try(
                                .dot("init").call([.init(label: "from", expression: .identifierPattern("decoder"))])
                            )
                        )
                    )
                ]
            )
        )
        desc.members.append(
            .function(
                accessModifier: desc.accessModifier,
                kind: .function(name: "encode"),
                parameters: [.init(label: "to", name: "encoder", type: .any(.member(["Swift", "Encoder"])))],
                keywords: [.throws],
                body: [
                    .expression(
                        .try(
                            .selfDot("storage").dot("encode")
                                .call([.init(label: "to", expression: .identifierPattern("encoder"))])
                        )
                    )
                ]
            )
        )

        // Reflect the stored properties rather than the box, so that `Mirror`-based output such as
        // `String(describing:)` and custom dumps is the same as for the unboxed struct.
        desc.conformances.append("Swift.CustomReflectable")
        let mirrorType = ExistingTypeDescription.member(["Swift", "Mirror"])
        desc.members.append(
            .variable(
                accessModifier: desc.accessModifier,
                kind: .var,
                left: "customMirror",
                type: mirrorType,
                getter: [
                    .expression(
                        .identifierType(mirrorType)
                            .call([
                                .init(label: nil, expression: .identifierPattern("self")),
                                .init(
                                    label: "children",
                                    expression: .identifierType(mirrorType)
                                        .call([.init(label: "reflecting", expression: .selfDot("storage").dot("value"))]
                                        )
                                        .dot("children")
                                ), .init(label: "displayStyle", expression: .dot("struct")),
                            ])
                    )
                ]
            )
        )

        desc.members.append(
            .commentable(
                .doc(
                    "Internal reference storage, so that embedding types hold a reference instead of the inline value."
                ),
                .variable(
                    accessModifier: .private,
                    kind: .var,
                    left: "storage",
                    type: .generic(wrapper: .init(TypeName.box), wrapped: .member("Storage"))
                )
            )
        )
        desc.members.append(.struct(storageDesc))

        return desc
    }

    /// Boxes the provided enum description.
    /// - Parameter desc: The enum description to box.
    /// - Returns: A boxed variant of the provided enum description.
    private func boxedEnum(_ desc: EnumDescription) -> EnumDescription {
        // Just mark it as indirect, done.
        var desc = desc
        desc.isIndirect = true
        return desc
    }
}

/// Estimates the inline size (`MemoryLayout<T>.size` on a 64-bit platform) of
/// the generated `Components.Schemas.*` types and decides which ones to box so
/// that no type stores more than a configured number of bytes inline.
///
/// The estimate is a heuristic rather than an ABI guarantee. Where it is unsure
/// it errs towards overestimating, as boxing a type early is harmless.
///
/// Every type that embeds a large struct copies it field by field in its value
/// witnesses, `==` and `hash(into:)`, and so does every type embedding that
/// one. Boxing is decided bottom-up: a type is only boxed if it is still over
/// the limit once the types it embeds have been boxed, which keeps the number
/// of boxed types small.
///
/// Inline types nested in a schema are boxed by the same rule, so a large
/// nested payload does not force its enclosing schema to be boxed as well.
struct InlineSizeEstimator {

    /// An estimated size and alignment.
    struct Layout: Equatable {
        var size: Int
        var alignment: Int
        /// Whether the type has unused bit patterns an enclosing `Optional` or enum can use as its tag.
        var hasExtraInhabitants: Bool

        static let pointer = Layout(size: 8, alignment: 8, hasExtraInhabitants: true)
        static let word = Layout(size: 8, alignment: 8, hasExtraInhabitants: false)
        static let byteEnum = Layout(size: 1, alignment: 1, hasExtraInhabitants: true)
    }

    /// The largest estimated inline size a type may have before it is boxed.
    let maxInlineSize: Int

    /// Top-level and nested type declarations, keyed by their fully qualified name components.
    private var decls: [[String]: Declaration] = [:]
    private var layouts: [[String]: Layout] = [:]
    private var inProgress: Set<[String]> = []

    /// Names of the top-level schemas to box.
    private(set) var boxedSchemaNames: Set<String>

    /// Fully qualified names of the nested enums to make indirect and nested structs to box.
    private(set) var boxedNestedTypes: Set<[String]> = []

    init(schemaDecls: [Declaration], alreadyBoxed: Set<String>, maxInlineSize: Int) {
        self.maxInlineSize = maxInlineSize
        self.boxedSchemaNames = alreadyBoxed
        for decl in schemaDecls { register(decl, parent: Constants.Components.Schemas.components) }
    }

    /// Estimates every registered top-level schema, deciding which to box along the way.
    mutating func run() {
        let prefixCount = Constants.Components.Schemas.components.count
        let paths = decls.keys.filter { $0.count == prefixCount + 1 }.sorted { $0.last! < $1.last! }
        for path in paths { _ = layout(ofDeclAt: path) }
        // The layout of an already boxed schema is a pointer, so its fields are not estimated along the
        // way. Estimate them now, so that the types nested in it follow the same rule.
        for path in paths where boxedSchemaNames.contains(path.last!) {
            guard let decl = decls[path], inProgress.insert(path).inserted else { continue }
            _ = unboxedLayout(of: decl, at: path)
            inProgress.remove(path)
        }
    }

    private mutating func register(_ decl: Declaration, parent: [String]) {
        let stripped = decl.strippingCommentsAndDeprecation
        let members: [Declaration]
        switch stripped {
        case .struct(let desc): members = desc.members
        case .enum(let desc): members = desc.members
        case .typealias: members = []
        default: return
        }
        guard let name = stripped.name else { return }
        let path = parent + [name]
        decls[path] = stripped
        for member in members { register(member, parent: path) }
    }

    private mutating func layout(ofDeclAt path: [String]) -> Layout {
        if let known = layouts[path] { return known }
        let isTopLevel = path.count == Constants.Components.Schemas.components.count + 1
        if isTopLevel, boxedSchemaNames.contains(path.last!) { return .pointer }
        guard let decl = decls[path] else { return .word }
        // A cycle the recursion detector did not box can only go through a heap reference.
        guard inProgress.insert(path).inserted else { return .pointer }
        defer { inProgress.remove(path) }

        var result = unboxedLayout(of: decl, at: path)
        if result.size > maxInlineSize, decl.isBoxable {
            if isTopLevel { boxedSchemaNames.insert(path.last!) } else { boxedNestedTypes.insert(path) }
            result = .pointer
        }
        layouts[path] = result
        return result
    }

    /// Estimates the layout of the provided declaration as generated, before any size-based boxing.
    private mutating func unboxedLayout(of decl: Declaration, at path: [String]) -> Layout {
        switch decl {
        case .struct(let desc):
            let storedTypes = desc.members.compactMap { member -> ExistingTypeDescription? in
                guard case .variable(let variable) = member.strippingCommentsAndDeprecation, !variable.isStatic,
                    variable.getter == nil
                else { return nil }
                return variable.type
            }
            return structLayout(of: storedTypes.map { layout(of: $0, context: path) })
        case .enum(let desc):
            let payloads = desc.members.compactMap { member -> [ExistingTypeDescription]? in
                guard case .enumCase(let enumCase) = member.strippingCommentsAndDeprecation,
                    case .nameWithAssociatedValues(let values) = enumCase.kind
                else { return nil }
                return values.map(\.type)
            }
            let payloadLayouts = payloads.map { types in structLayout(of: types.map { layout(of: $0, context: path) }) }
            return desc.isIndirect ? .pointer : enumLayout(payloads: payloadLayouts)
        case .typealias(let desc): return layout(of: desc.existingType, context: path)
        default: return .word
        }
    }

    private mutating func layout(of type: ExistingTypeDescription, context: [String]) -> Layout {
        switch type {
        case .any: return Layout(size: 40, alignment: 8, hasExtraInhabitants: true)
        case .array, .dictionaryValue: return .pointer
        case .optional(let wrapped):
            var wrappedLayout = layout(of: wrapped, context: context)
            if wrappedLayout.hasExtraInhabitants { return wrappedLayout }
            wrappedLayout.size += 1
            return wrappedLayout
        case .generic(let wrapper, let wrapped):
            guard case .member(let components) = wrapper else { return layout(of: wrapped, context: context) }
            switch components.joined(separator: ".") {
            case "OpenAPIRuntime.CopyOnWriteBox", "OpenAPIRuntime.MultipartBody": return .pointer
            case "OpenAPIRuntime.MultipartPart":
                // The payload and an optional file name.
                return structLayout(of: [layout(of: wrapped, context: context), Self.builtinLayouts["Swift.String"]!])
            case "OpenAPIRuntime.MultipartDynamicallyNamedPart":
                // The payload, an optional file name, and an optional part name.
                let string = Self.builtinLayouts["Swift.String"]!
                return structLayout(of: [layout(of: wrapped, context: context), string, string])
            default: return layout(of: wrapped, context: context)
            }
        case .member(let components):
            if let builtin = Self.builtinLayouts[components.joined(separator: ".")] { return builtin }
            // Nested types are referenced either fully qualified or relative to the enclosing type.
            var scope = context
            while true {
                let candidate = scope + components
                if decls[candidate] != nil { return layout(ofDeclAt: candidate) }
                if scope.isEmpty { break }
                scope.removeLast()
            }
            return .word
        }
    }

    private func structLayout(of fields: [Layout]) -> Layout {
        var size = 0
        var alignment = 1
        var hasExtraInhabitants = false
        for field in fields {
            size = (size + field.alignment - 1) / field.alignment * field.alignment + field.size
            alignment = max(alignment, field.alignment)
            hasExtraInhabitants = hasExtraInhabitants || field.hasExtraInhabitants
        }
        return Layout(size: size, alignment: alignment, hasExtraInhabitants: hasExtraInhabitants)
    }

    private func enumLayout(payloads: [Layout]) -> Layout {
        guard let largest = payloads.max(by: { $0.size < $1.size }) else { return .byteEnum }
        let alignment = payloads.map(\.alignment).max() ?? 1
        // A single payload case can keep its tag in the payload's extra inhabitants.
        let needsTag = !(payloads.count == 1 && largest.hasExtraInhabitants)
        return Layout(size: largest.size + (needsTag ? 1 : 0), alignment: alignment, hasExtraInhabitants: true)
    }

    private static let builtinLayouts: [String: Layout] = [
        "Swift.String": Layout(size: 16, alignment: 8, hasExtraInhabitants: true), "Swift.Int": .word,
        "Swift.Int64": .word, "Swift.UInt": .word, "Swift.UInt64": .word, "Swift.Double": .word,
        "Swift.Int32": Layout(size: 4, alignment: 4, hasExtraInhabitants: false),
        "Swift.UInt32": Layout(size: 4, alignment: 4, hasExtraInhabitants: false),
        "Swift.Float": Layout(size: 4, alignment: 4, hasExtraInhabitants: false),
        "Swift.Bool": Layout(size: 1, alignment: 1, hasExtraInhabitants: true), "Foundation.Date": .word,
        "Foundation.URL": Layout(size: 16, alignment: 8, hasExtraInhabitants: true),
        "Foundation.Data": Layout(size: 16, alignment: 8, hasExtraInhabitants: true),
        "Foundation.UUID": Layout(size: 16, alignment: 1, hasExtraInhabitants: false),
        "OpenAPIRuntime.OpenAPIValueContainer": Layout(size: 32, alignment: 8, hasExtraInhabitants: true),
        "OpenAPIRuntime.OpenAPIObjectContainer": .pointer, "OpenAPIRuntime.OpenAPIArrayContainer": .pointer,
        "OpenAPIRuntime.Base64EncodedData": Layout(size: 32, alignment: 8, hasExtraInhabitants: true),
        "OpenAPIRuntime.HTTPBody": .pointer,
        "OpenAPIRuntime.MultipartRawPart": Layout(size: 16, alignment: 8, hasExtraInhabitants: true),
    ]
}

extension Declaration {

    /// The declaration without any enclosing comment or deprecation wrappers.
    fileprivate var strippingCommentsAndDeprecation: Declaration {
        switch self {
        case .commentable(_, let decl), .deprecated(_, let decl): return decl.strippingCommentsAndDeprecation
        default: return self
        }
    }
}
