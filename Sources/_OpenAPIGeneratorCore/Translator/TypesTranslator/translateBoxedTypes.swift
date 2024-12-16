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
        let nodeLookup = Dictionary(uniqueKeysWithValues: nodes.map { ($0.name, $0) })
        let container = DeclarationRecursionDetector.Container(lookupMap: nodeLookup)

        let boxedNames = try RecursionDetector.computeBoxedTypes(rootNodes: nodes, container: container)

        var decls = decls
        for (index, decl) in decls.enumerated() {
            guard let name = decl.name, boxedNames.contains(name) else { continue }
            try diagnostics.emit(
                .note(
                    message: "Detected a recursive type; it will be boxed to break the reference cycle.",
                    context: ["name": name]
                )
            )
            decls[index] = boxedType(decl)
        }
        return decls
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
    /// - Parameter desc: The struct description to box.
    /// - Returns: A boxed variant of the provided struct description.
    private func boxedStruct(_ desc: StructDescription) -> StructDescription {

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
                    Constants.Components.Schemas.components + [desc.name, Constants.Codable.codingKeysName]
                )
            )
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
                parameters: [.init(label: "from", name: "decoder", type: .any(.member("Decoder")))],
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
                parameters: [.init(label: "to", name: "encoder", type: .any(.member("Encoder")))],
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

        desc.members.append(
            .commentable(
                .doc("Internal reference storage to allow type recursion."),
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
