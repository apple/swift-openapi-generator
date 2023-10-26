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

extension Comment {

    /// Returns the string contents of the comment.
    var contents: String {
        switch self {
        case .inline(let string): return string
        case .doc(let string): return string
        case .mark(let string, _): return string
        }
    }

    /// Returns the first line of content, unless it starts with a dash.
    ///
    /// Lines starting with a dash are appended remarks, which don't
    /// describe the property.
    var firstLineOfContent: String? {
        guard let line = contents.split(separator: "\n").first, !line.hasPrefix("-") else { return nil }
        return String(line)
    }

    /// Returns a documentation comment given a prefix and a suffix.
    ///
    /// If both are present, an empty line is added between the prefix
    /// and suffix.
    ///
    /// Returns nil if neither is present.
    /// - Parameters:
    ///   - prefix: The string that comes first.
    ///   - suffix: The string that comes second.
    /// - Returns: A documentation comment if either prefix or suffix is provided; otherwise, nil.
    static func doc(prefix: String?, suffix: String?) -> Self? { text(prefix: prefix, suffix: suffix).map { .doc($0) } }

    /// Returns a string created by joining the specified prefix and
    /// suffix strings with a newline.
    ///
    /// If either parameter is nil, no newline is added.
    ///
    /// Returns nil if both parameters are nil.
    /// - Parameters:
    ///   - prefix: The string that comes first.
    ///   - suffix: The string that comes second.
    /// - Returns: A string with the joined prefix and suffix separated by a newline, or nil if both are nil.
    private static func text(prefix: String?, suffix: String?) -> String? {
        if let prefix, let suffix { return "\(prefix)\n\n\(suffix)" }
        if let prefix { return prefix }
        if let suffix { return suffix }
        return nil
    }
}

extension TypeName {

    /// Returns a string representing the "generated from" comment.
    ///
    /// Returns nil if the type name has no JSON path.
    var generatedFromCommentText: String? {
        guard let fullyQualifiedJSONPath else { return nil }
        return "- Remark: Generated from `\(fullyQualifiedJSONPath)`."
    }

    /// Returns a documentation comment by appending the "generated from"
    /// string to the specified user description.
    /// - Parameter userDescription: The description specified by the user
    /// in the OpenAPI document.
    /// - Returns: A documentation comment combining the user description and the "generated from" string.
    func docCommentWithUserDescription(_ userDescription: String?) -> Comment? {
        .doc(prefix: userDescription, suffix: generatedFromCommentText)
    }

    /// Returns a documentation comment by appending the "generated from"
    /// string to the specified user description.
    ///
    /// The "generated from" string also includes a subpath.
    /// - Parameters:
    ///  - userDescription: The description specified by the user.
    ///  - subPath: A subpath appended to the JSON path of this
    /// type name.
    /// - Returns: A documentation  comment with the "generated from" string
    ///            appended to the user description  or nil if not available.
    func docCommentWithUserDescription(_ userDescription: String?, subPath: String) -> Comment? {
        guard let jsonPath = appending(jsonComponent: subPath).fullyQualifiedJSONPath else {
            return Comment.doc(prefix: userDescription, suffix: nil)
        }
        return Comment.doc(prefix: userDescription, suffix: "- Remark: Generated from `\(jsonPath)`.")
    }
}

extension ResponseKind {

    /// Returns a string describing the response kind, which is used in a
    /// generated documentation comment.
    private var commentDescription: String {
        switch self {
        case .`default`: return "default"
        case .code(let int): return "\(int) \(HTTPStatusCodes.safeName(for: int))"
        case .range(let rangeType): return "\(rangeType.lowerBound)...\(rangeType.upperBound) \(rangeType.prettyName)"
        }
    }

    /// Returns a documentation comment for the specified OpenAPI description
    /// and a JSON path.
    /// - Parameters:
    ///   - userDescription: The comment provided by the user in the OpenAPI
    ///   document.
    ///   - jsonPath: The JSON path of the commented type.
    /// - Returns: A documentation comment with information about the source JSON path and HTTP response code.
    func docComment(userDescription: String?, jsonPath: String) -> Comment? {
        .doc(
            prefix: userDescription,
            suffix: """
                - Remark: Generated from `\(jsonPath)`.

                HTTP response code: `\(commentDescription)`.
                """
        )
    }
}

extension TypedParameter {
    /// Returns a documentation comment for the parameter.
    /// - Parameter parent: The parent type of the parameter.
    ///  - Returns: A documentation comment for the parameter or nil if not available.
    func docComment(parent: TypeName) -> Comment? {
        parent.docCommentWithUserDescription(
            parameter.description,
            subPath: "\(parameter.location.rawValue)/\(parameter.name)"
        )
    }
}

extension ContentType {
    /// Returns a documentation comment for the content type.
    /// - Parameter typeName: The type name of the content.
    /// - Returns: A documentation comment for the content type or nil if not available.
    func docComment(typeName: TypeName) -> Comment? {
        typeName.docCommentWithUserDescription(nil, subPath: lowercasedTypeSubtypeAndParametersWithEscape)
    }
}

extension Comment {

    /// Returns a reference documentation string to attach to the generated function for an operation.
    /// - Parameter operationDescription: The details of the operation from the OpenAPI document.
    init(from operationDescription: OperationDescription) {
        self.init(
            summary: operationDescription.operation.summary,
            description: operationDescription.operation.description,
            httpMethod: operationDescription.httpMethod,
            path: operationDescription.path,
            openAPIDocumentPath: operationDescription.jsonPathComponent
        )
    }

    /// Returns a reference documentation string to attach to the generated function for an operation.
    ///
    /// - Parameters:
    ///   - summary: A short summary of what the operation does.
    ///   - description: A verbose explanation of the operation behavior.
    ///   - httpMethod: The HTTP method associated with this operation.
    ///   - path: The path associated with this operation.
    ///   - openAPIDocumentPath: JSONPath to the operation element in the OpenAPI document.
    init(
        summary: String?,
        description: String?,
        httpMethod: OpenAPI.HttpMethod,
        path: OpenAPI.Path,
        openAPIDocumentPath: String
    ) {
        var lines: [String] = []
        if let summary {
            lines.append(summary)
            lines.append("")
        }
        if let description {
            lines.append(description)
            lines.append("")
        }
        lines.append(contentsOf: [
            "- Remark: HTTP `\(httpMethod.rawValue.uppercased()) \(path.rawValue)`.",
            "- Remark: Generated from `\(openAPIDocumentPath)`.",
        ])
        self = .doc(lines.joined(separator: "\n"))
    }

    /// Returns a documentation comment for the Operations namespace.
    static func operationsNamespace() -> Self {
        .doc(#"API operations, with input and output types, generated from `#/paths` in the OpenAPI document."#)
    }

    /// Returns a documentation comment for a property with the specified
    /// name, OpenAPI description, and parent type.
    /// - Parameters:
    ///   - originalName: The name as provided by the user in the OpenAPI
    ///   document.
    ///   - userDescription: The description as provided by the user in the
    ///   OpenAPI document.
    ///   - parent: The Swift type name of the structure of which this is
    ///   a property of.
    /// - Returns: A documentation comment for the property.
    static func property(originalName: String, userDescription: String?, parent: TypeName) -> Comment? {
        .doc(
            prefix: userDescription,
            suffix: parent.fullyQualifiedJSONPath.flatMap { jsonPath in
                "- Remark: Generated from `\(jsonPath)/\(originalName)`."
            }
        )
    }

    /// Returns a documentation comment for a child schema with the specified
    /// name, OpenAPI description, and parent type.
    /// - Parameters:
    ///   - originalName: A naming hint.
    ///   - userDescription: The description as provided by the user in the
    ///   OpenAPI document.
    ///   - parent: The Swift type name of the structure of which this is
    ///   a child of.
    /// - Returns: A documentation comment for the property.
    static func child(originalName: String, userDescription: String?, parent: TypeName) -> Comment? {
        .doc(
            prefix: userDescription,
            suffix: parent.fullyQualifiedJSONPath.flatMap { jsonPath in
                "- Remark: Generated from `\(jsonPath)/\(originalName)`."
            }
        )
    }
    /// Returns a documentation comment for a function with the provided
    /// parameters.
    /// - Parameters:
    ///   - abstract: The documentation of the function.
    ///   - parameters: The parameters.
    /// - Returns: A documentation comment for the function.
    static func functionComment(abstract: String?, parameters: [(name: String, comment: String?)]) -> Comment? {
        guard !parameters.isEmpty else { return abstract.map { .doc($0) } }
        var components: [String] = abstract.map { [$0] } ?? []
        var parameterComponents: [String] = []
        parameterComponents.append("- Parameters:")
        for (name, comment) in parameters {
            let parameterComment: String
            if let comment {
                parameterComment = Comment.doc(comment).firstLineOfContent.map { " \($0)" } ?? ""
            } else {
                parameterComment = ""
            }
            parameterComponents.append("  - \(name):\(parameterComment)")
        }
        components.append("")
        components.append(parameterComponents.joined(separator: "\n"))
        return .doc(components.joined(separator: "\n"))
    }
}

extension ComponentDictionaryLocatable {

    /// Returns a documentation comment for the Components section.
    ///
    /// Examples of sections: "Schemas", "Parameters", and so on.
    /// - Returns: A documentation comment for the property.
    static func sectionComment() -> Comment {
        .doc(
            """
            Types generated from the `#/components/\(Self.openAPIComponentsKey)` section of the OpenAPI document.
            """
        )
    }
}
