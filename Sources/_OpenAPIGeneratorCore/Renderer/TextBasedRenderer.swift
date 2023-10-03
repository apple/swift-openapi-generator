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

/// A renderer that uses string interpolation and concatenation
/// to convert the provided structure code into raw string form.
struct TextBasedRenderer: RendererProtocol {

    func render(
        structured: StructuredSwiftRepresentation,
        config: Config,
        diagnostics: any DiagnosticCollector
    ) throws -> InMemoryOutputFile {
        let namedFile = structured.file
        return InMemoryOutputFile(
            baseName: namedFile.name,
            contents: renderFile(namedFile.contents)
        )
    }

    // MARK: - Internals

    /// Renders the specified Swift file.
    func renderFile(_ description: FileDescription) -> Data {
        Data(renderedFile(description).utf8)
    }

    /// Renders the specified comment.
    func renderedComment(_ comment: Comment) -> String {
        let prefix: String
        let commentString: String
        switch comment {
        case .inline(let string):
            prefix = "//"
            commentString = string
        case .doc(let string):
            prefix = "///"
            commentString = string
        case .mark(let string, sectionBreak: true):
            prefix = "// MARK: -"
            commentString = string
        case .mark(let string, sectionBreak: false):
            prefix = "// MARK:"
            commentString = string
        }
        return
            commentString
            .transformingLines { line in
                if line.isEmpty {
                    return prefix
                }
                return "\(prefix) \(line)"
            }
    }

    /// Renders the specified import statements.
    func renderedImports(_ imports: [ImportDescription]?) -> String {
        (imports ?? [])
            .map(renderImport(_:))
            .joinedLines()
    }

    /// Renders a single import statement.
    func renderImport(_ description: ImportDescription) -> String {
        func render(preconcurrency: Bool) -> String {
            let spiPrefix = description.spi.map { "@_spi(\($0)) " } ?? ""
            let preconcurrencyPrefix = preconcurrency ? "@preconcurrency " : ""
            var types = [String]()
            if let moduleTypes = description.moduleTypes {
                types = moduleTypes.map {
                    "\(preconcurrencyPrefix)\(spiPrefix)import \($0)"
                }
                return types.joinedLines()
            }
            return "\(preconcurrencyPrefix)\(spiPrefix)import \(description.moduleName)"
        }

        switch description.preconcurrency {
        case .always:
            return render(preconcurrency: true)
        case .never:
            return render(preconcurrency: false)
        case .onOS(let operatingSystems):
            var lines = [String]()
            lines.append("#if \(operatingSystems.map { "os(\($0))" }.joined(separator: " || "))")
            lines.append(render(preconcurrency: true))
            lines.append("#else")
            lines.append(render(preconcurrency: false))
            lines.append("#endif")
            return lines.joinedLines()
        }
    }

    /// Renders the specified access modifier.
    func renderedAccessModifier(_ accessModifier: AccessModifier) -> String {
        switch accessModifier {
        case .public:
            return "public"
        case .internal:
            return "internal"
        case .fileprivate:
            return "fileprivate"
        case .private:
            return "private"
        }
    }

    /// Renders the specified identifier.
    func renderedIdentifier(_ identifier: IdentifierDescription) -> String {
        return identifier.name
    }

    /// Renders the specified member access expression.
    func renderedMemberAccess(_ memberAccess: MemberAccessDescription) -> String {
        let left = memberAccess.left.flatMap { renderedExpression($0) } ?? ""
        return "\(left).\(memberAccess.right)"
    }

    /// Renders the specified function call argument.
    func renderedFunctionCallArgument(_ arg: FunctionArgumentDescription) -> String {
        let left = arg.label.flatMap { "\($0): " } ?? ""
        return left + renderedExpression(arg.expression)
    }

    /// Renders the specified function call.
    func renderedFunctionCall(_ functionCall: FunctionCallDescription) -> String {
        let arguments = functionCall.arguments
        return
            "\(renderedExpression(functionCall.calledExpression))(\(arguments.map(renderedFunctionCallArgument).joined(separator: ", ")))"
    }

    /// Renders the specified assignment expression.
    func renderedAssignment(_ assignment: AssignmentDescription) -> String {
        return "\(renderedExpression(assignment.left)) = \(renderedExpression(assignment.right))"
    }

    /// Renders the specified switch case kind.
    func renderedSwitchCaseKind(_ kind: SwitchCaseKind) -> String {
        switch kind {
        case let .`case`(expression, associatedValueNames):
            let associatedValues: String
            let maybeLet: String
            if !associatedValueNames.isEmpty {
                associatedValues = "(" + associatedValueNames.joined(separator: ", ") + ")"
                maybeLet = "let "
            } else {
                associatedValues = ""
                maybeLet = ""
            }
            return "case \(maybeLet)\(renderedExpression(expression))\(associatedValues)"
        case .multiCase(let expressions):
            let expressions = expressions.map(renderedExpression).joined(separator: ", ")
            return "case \(expressions)"
        case .`default`:
            return "default"
        }
    }

    /// Renders the specified switch case.
    func renderedSwitchCase(_ switchCase: SwitchCaseDescription) -> String {
        var lines: [String] = []
        lines.append(renderedSwitchCaseKind(switchCase.kind) + ":")
        lines.append(renderedCodeBlocks(switchCase.body))
        return lines.joinedLines()
    }

    /// Renders the specified switch expression.
    func renderedSwitch(_ switchDesc: SwitchDescription) -> String {
        var lines: [String] = ["switch \(renderedExpression(switchDesc.switchedExpression)) {"]
        for caseDesc in switchDesc.cases {
            lines.append(renderedSwitchCase(caseDesc))
        }
        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified if statement.
    func renderedIf(_ ifDesc: IfStatementDescription) -> String {
        var lines: [String] = []
        let ifBranch = ifDesc.ifBranch
        lines.append("if \(renderedExpression(ifBranch.condition)) {")
        lines.append(renderedCodeBlocks(ifBranch.body))
        lines.append("}")
        for branch in ifDesc.elseIfBranches {
            lines.append("else if \(renderedExpression(branch.condition)) {")
            lines.append(renderedCodeBlocks(branch.body))
            lines.append("}")
        }
        if let elseBody = ifDesc.elseBody {
            lines.append("else {")
            lines.append(renderedCodeBlocks(elseBody))
            lines.append("}")
        }
        return lines.joinedLines()
    }

    /// Renders the specified switch expression.
    func renderedDoStatement(_ description: DoStatementDescription) -> String {
        var lines: [String] = ["do {"]
        lines.append(renderedCodeBlocks(description.doStatement))
        if let catchBody = description.catchBody {
            lines.append("} catch {")
            lines.append(renderedCodeBlocks(catchBody))
        }
        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified value binding expression.
    func renderedValueBinding(_ valueBinding: ValueBindingDescription) -> String {
        return "\(renderedBindingKind(valueBinding.kind)) \(renderedFunctionCall(valueBinding.value))"
    }

    /// Renders the specified keyword.
    func renderedKeywordKind(_ kind: KeywordKind) -> String {
        switch kind {
        case .return:
            return "return"
        case .try(hasPostfixQuestionMark: let hasPostfixQuestionMark):
            return "try\(hasPostfixQuestionMark ? "?" : "")"
        case .await:
            return "await"
        case .throw:
            return "throw"
        }
    }

    /// Renders the specified unary keyword expression.
    func renderedUnaryKeywordExpression(_ expression: UnaryKeywordDescription) -> String {
        let keyword = renderedKeywordKind(expression.kind)
        guard let expr = expression.expression else {
            return keyword
        }
        return "\(keyword) \(renderedExpression(expr))"
    }

    /// Renders the specified closure invocation.
    func renderedClosureInvocation(_ invocation: ClosureInvocationDescription) -> String {
        var lines: [String] = []
        var signatureWords: [String] = ["{"]
        if !invocation.argumentNames.isEmpty {
            signatureWords.append(invocation.argumentNames.joined(separator: ", "))
            signatureWords.append("in")
        }
        lines.append(signatureWords.joinedWords())
        if let body = invocation.body {
            lines.append(renderedCodeBlocks(body))
        }
        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified binary operator.
    func renderedBinaryOperator(_ op: BinaryOperator) -> String {
        op.rawValue
    }

    /// Renders the specified binary operation.
    func renderedBinaryOperation(_ operation: BinaryOperationDescription) -> String {
        renderedExpression(operation.left) + " "
            + renderedBinaryOperator(operation.operation) + " "
            + renderedExpression(operation.right)
    }

    /// Renders the specified inout expression.
    func renderedInOutDescription(_ description: InOutDescription) -> String {
        "&" + renderedExpression(description.referencedExpr)
    }

    /// Renders the specified optional chaining expression.
    func renderedOptionalChainingDescription(
        _ description: OptionalChainingDescription
    ) -> String {
        renderedExpression(description.referencedExpr) + "?"
    }

    /// Renders the specified tuple expression.
    func renderedTupleDescription(
        _ description: TupleDescription
    ) -> String {
        "(" + description.members.map(renderedExpression).joined(separator: ", ") + ")"
    }

    /// Renders the specified expression.
    func renderedExpression(_ expression: Expression) -> String {
        switch expression {
        case .literal(let literalDescription):
            return renderedLiteral(literalDescription)
        case .identifier(let identifierDescription):
            return renderedIdentifier(identifierDescription)
        case .memberAccess(let memberAccessDescription):
            return renderedMemberAccess(memberAccessDescription)
        case .functionCall(let functionCallDescription):
            return renderedFunctionCall(functionCallDescription)
        case .assignment(let assignment):
            return renderedAssignment(assignment)
        case .switch(let switchDesc):
            return renderedSwitch(switchDesc)
        case .ifStatement(let ifDesc):
            return renderedIf(ifDesc)
        case .doStatement(let doStmt):
            return renderedDoStatement(doStmt)
        case .valueBinding(let valueBinding):
            return renderedValueBinding(valueBinding)
        case .unaryKeyword(let unaryKeyword):
            return renderedUnaryKeywordExpression(unaryKeyword)
        case .closureInvocation(let closureInvocation):
            return renderedClosureInvocation(closureInvocation)
        case .binaryOperation(let binaryOperation):
            return renderedBinaryOperation(binaryOperation)
        case .inOut(let inOut):
            return renderedInOutDescription(inOut)
        case .optionalChaining(let optionalChaining):
            return renderedOptionalChainingDescription(optionalChaining)
        case .tuple(let tuple):
            return renderedTupleDescription(tuple)
        }
    }

    /// Renders the specified literal expression.
    func renderedLiteral(_ literal: LiteralDescription) -> String {
        switch literal {
        case let .string(string):
            return "\"\(string)\""
        case let .int(int):
            return "\(int)"
        case let .bool(bool):
            return bool ? "true" : "false"
        case .nil:
            return "nil"
        case .array(let items):
            return "[\(items.map { renderedExpression($0) }.joined(separator: ", "))]"
        }
    }

    /// Renders the specified where clause requirement.
    func renderedWhereClauseRequirement(_ requirement: WhereClauseRequirement) -> String {
        switch requirement {
        case .conformance(let left, let right):
            return "\(left): \(right)"
        }
    }

    /// Renders the specified where clause.
    func renderedWhereClause(_ clause: WhereClause) -> String {
        let renderedRequirements = clause.requirements.map(renderedWhereClauseRequirement)
        return "where \(renderedRequirements.joined(separator: ", "))"
    }

    /// Renders the specified extension declaration.
    func renderedExtension(_ extensionDescription: ExtensionDescription) -> String {
        var signatureWords: [String] = []
        if let accessModifier = extensionDescription.accessModifier {
            signatureWords.append(renderedAccessModifier(accessModifier))
        }
        signatureWords.append("extension")
        signatureWords.append(extensionDescription.onType)
        if !extensionDescription.conformances.isEmpty {
            signatureWords.append(":")
            signatureWords.append(extensionDescription.conformances.joined(separator: ", "))
        }
        if let whereClause = extensionDescription.whereClause {
            signatureWords.append(renderedWhereClause(whereClause))
        }
        var lines: [String] = []
        lines.append("\(signatureWords.joinedWords()) {")
        for declaration in extensionDescription.declarations {
            lines.append(renderedDeclaration(declaration))
        }
        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified typealias declaration.
    func renderedTypealias(_ alias: TypealiasDescription) -> String {
        var words: [String] = []
        if let accessModifier = alias.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        words.append(contentsOf: [
            "typealias",
            alias.name,
            "=",
            alias.existingType,
        ])
        return words.joinedWords()
    }

    /// Renders the specified binding kind.
    func renderedBindingKind(_ kind: BindingKind) -> String {
        switch kind {
        case .var:
            return "var"
        case .let:
            return "let"
        }
    }

    /// Renders the specified variable declaration.
    func renderedVariable(_ variable: VariableDescription) -> String {
        var words: [String] = []
        if let accessModifier = variable.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        if variable.isStatic {
            words.append("static")
        }
        words.append(renderedBindingKind(variable.kind))
        let labelWithOptionalType: String
        if let type = variable.type {
            labelWithOptionalType = "\(variable.left): \(type)"
        } else {
            labelWithOptionalType = variable.left
        }
        words.append(labelWithOptionalType)

        if let right = variable.right {
            words.append("= \(renderedExpression(right))")
        }

        var lines: [String] = [words.joinedWords()]
        if let body = variable.getter {
            lines.append("{")
            if !variable.getterEffects.isEmpty {
                lines.append("get \(variable.getterEffects.map(renderedFunctionKeyword).joined(separator: " ")) {")
            }
            lines.append(renderedCodeBlocks(body))
            if !variable.getterEffects.isEmpty {
                lines.append("}")
            }
            lines.append("}")
        }
        return lines.joinedLines()
    }

    /// Renders the specified struct declaration.
    func renderedStruct(_ structDesc: StructDescription) -> String {
        var words: [String] = []
        if let accessModifier = structDesc.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        words.append("struct")
        words.append(structDesc.name)
        if !structDesc.conformances.isEmpty {
            words.append(":")
            words.append(structDesc.conformances.joined(separator: ", "))
        }
        words.append("{")
        let declarationLine = words.joinedWords()

        var lines: [String] = []
        lines.append(declarationLine)

        for member in structDesc.members {
            lines.append(contentsOf: renderedDeclaration(member).asLines())
        }

        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified protocol declaration.
    func renderedProtocol(_ protocolDesc: ProtocolDescription) -> String {
        var words: [String] = []
        if let accessModifier = protocolDesc.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        words.append("protocol")
        words.append(protocolDesc.name)
        if !protocolDesc.conformances.isEmpty {
            words.append(":")
            words.append(protocolDesc.conformances.joined(separator: ", "))
        }
        words.append("{")
        let declarationLine = words.joinedWords()

        var lines: [String] = []
        lines.append(declarationLine)

        for member in protocolDesc.members {
            lines.append(contentsOf: renderedDeclaration(member).asLines())
        }

        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified enum declaration.
    func renderedEnum(_ enumDesc: EnumDescription) -> String {
        var words: [String] = []
        if enumDesc.isFrozen {
            words.append("@frozen")
        }
        if let accessModifier = enumDesc.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        words.append("enum")
        words.append(enumDesc.name)
        if !enumDesc.conformances.isEmpty {
            words.append(":")
            words.append(enumDesc.conformances.joined(separator: ", "))
        }
        words.append("{")
        let declarationLine = words.joinedWords()

        var lines: [String] = []
        lines.append(declarationLine)

        for member in enumDesc.members {
            lines.append(contentsOf: renderedDeclaration(member).asLines())
        }

        lines.append("}")
        return lines.joinedLines()
    }

    /// Renders the specified enum case associated value.
    func renderedEnumCaseAssociatedValue(_ value: EnumCaseAssociatedValueDescription) -> String {
        var words: [String] = []
        if let label = value.label {
            words.append(label)
            words.append(":")
        }
        words.append(value.type)
        return words.joinedWords()
    }

    /// Renders the specified enum case kind.
    func renderedEnumCaseKind(_ kind: EnumCaseKind) -> String {
        switch kind {
        case .nameOnly:
            return ""
        case .nameWithRawValue(let rawValue):
            return " = \(renderedLiteral(rawValue))"
        case .nameWithAssociatedValues(let values):
            if values.isEmpty {
                return ""
            }
            let associatedValues =
                values
                .map(renderedEnumCaseAssociatedValue)
                .joined(separator: ", ")
            return "(\(associatedValues))"
        }
    }

    /// Renders the specified enum case declaration.
    func renderedEnumCase(_ enumCase: EnumCaseDescription) -> String {
        return "case \(enumCase.name)\(renderedEnumCaseKind(enumCase.kind))"
    }

    /// Renders the specified declaration.
    func renderedDeclaration(_ declaration: Declaration) -> String {
        switch declaration {
        case let .commentable(comment, nestedDeclaration):
            return renderedCommentableDeclaration(comment: comment, declaration: nestedDeclaration)
        case let .deprecated(deprecation, nestedDeclaration):
            return renderedDeprecatedDeclaration(deprecation: deprecation, declaration: nestedDeclaration)
        case .variable(let variableDescription):
            return renderedVariable(variableDescription)
        case .extension(let extensionDescription):
            return renderedExtension(extensionDescription)
        case .struct(let structDescription):
            return renderedStruct(structDescription)
        case .protocol(let protocolDescription):
            return renderedProtocol(protocolDescription)
        case .enum(let enumDescription):
            return renderedEnum(enumDescription)
        case .typealias(let typealiasDescription):
            return renderedTypealias(typealiasDescription)
        case .function(let functionDescription):
            return renderedFunction(functionDescription)
        case .enumCase(let enumCase):
            return renderedEnumCase(enumCase)
        }
    }

    /// Renders the specified function kind.
    func renderedFunctionKind(_ functionKind: FunctionKind) -> String {
        switch functionKind {
        case .initializer(let isFailable):
            return "init\(isFailable ? "?" : "")"
        case .function(let name, let isStatic):
            return (isStatic ? "static " : "") + "func \(name)"
        }
    }

    /// Renders the specified function keyword.
    func renderedFunctionKeyword(_ keyword: FunctionKeyword) -> String {
        switch keyword {
        case .throws:
            return "throws"
        case .async:
            return "async"
        }
    }

    /// Renders the specified function signature.
    func renderedFunctionSignature(_ signature: FunctionSignatureDescription) -> String {
        var words: [String] = []
        if let accessModifier = signature.accessModifier {
            words.append(renderedAccessModifier(accessModifier))
        }
        words.append(renderedFunctionKind(signature.kind))
        words.append("(")
        words.append(signature.parameters.map(renderedParameter).joined(separator: ", "))
        words.append(")")
        for keyword in signature.keywords {
            words.append(renderedFunctionKeyword(keyword))
        }
        if let returnType = signature.returnType {
            words.append("->")
            words.append(renderedExpression(returnType))
        }
        return words.joinedWords()
    }

    /// Renders the specified function declaration.
    func renderedFunction(_ functionDescription: FunctionDescription) -> String {
        var lines: [String] = []
        var words: [String] = [
            renderedFunctionSignature(functionDescription.signature)
        ]
        if functionDescription.body != nil {
            words.append("{")
        }
        lines.append(words.joinedWords())

        if let body = functionDescription.body {
            lines.append(contentsOf: body.map(renderedCodeBlock))
        }

        if functionDescription.body != nil {
            lines.append("}")
        }
        return lines.joinedLines()
    }

    /// Renders the specified parameter declaration.
    func renderedParameter(_ parameterDescription: ParameterDescription) -> String {
        var words: [String] = []
        if let label = parameterDescription.label {
            words.append(label)
        } else {
            words.append("_")
        }
        if let name = parameterDescription.name {
            // If the label and name are the same value, don't repeat it, otherwise
            // swift-format emits a warning.
            if name != parameterDescription.label {
                words.append(name)
            }
        }
        words.append(":")
        words.append(parameterDescription.type)
        if let defaultValue = parameterDescription.defaultValue {
            words.append("=")
            words.append(renderedExpression(defaultValue))
        }
        return words.joinedWords()
    }

    /// Renders the specified declaration with a comment.
    func renderedCommentableDeclaration(comment: Comment?, declaration: Declaration) -> String {
        return [
            comment.map(renderedComment),
            renderedDeclaration(declaration),
        ]
        .compactMap({ $0 }).joinedLines()
    }

    /// Renders the specified declaration with a deprecation annotation.
    func renderedDeprecatedDeclaration(deprecation: DeprecationDescription, declaration: Declaration) -> String {
        return [
            renderedDeprecation(deprecation),
            renderedDeclaration(declaration),
        ]
        .joinedLines()
    }

    func renderedDeprecation(_ deprecation: DeprecationDescription) -> String {
        let things: [String] = [
            "*",
            "deprecated",
            deprecation.message.map { "message: \"\($0)\"" },
            deprecation.renamed.map { "renamed: \"\($0)\"" },
        ]
        .compactMap({ $0 })
        return "@available(\(things.joined(separator: ", ")))"
    }

    /// Renders the specified code block item.
    func renderedCodeBlockItem(_ description: CodeBlockItem) -> String {
        switch description {
        case .declaration(let declaration):
            return renderedDeclaration(declaration)
        case .expression(let expression):
            return renderedExpression(expression)
        }
    }

    /// Renders the specified code block.
    func renderedCodeBlock(_ description: CodeBlock) -> String {
        var lines: [String] = []
        if let comment = description.comment {
            lines.append(contentsOf: renderedComment(comment).asLines())
        }
        let item = description.item
        lines.append(contentsOf: renderedCodeBlockItem(item).asLines())
        return lines.joinedLines()
    }

    /// Renders the specified code blocks.
    func renderedCodeBlocks(_ blocks: [CodeBlock]) -> String {
        blocks.map(renderedCodeBlock).joinedLines()
    }

    /// Renders the specified file.
    func renderedFile(_ description: FileDescription) -> String {
        var lines: [String] = []
        if let topComment = description.topComment {
            lines.appendLines(from: renderedComment(topComment))
        }
        if let imports = description.imports {
            lines.appendLines(from: renderedImports(imports))
        }
        let renderedCodeBlocks = description.codeBlocks.map(renderedCodeBlock)
        for block in renderedCodeBlocks {
            lines.append(block)
            lines.append("")
        }
        return lines.joinedLines()
    }
}

fileprivate extension Array where Element == String {

    /// Appends the lines from the specified string.
    /// - Parameter string: The string whose lines to append.
    mutating func appendLines(from string: String) {
        append(contentsOf: string.asLines())
    }

    /// Returns a string where the elements of the array are
    /// joined by a newline character, with optionally omitting
    /// empty lines.
    /// - Parameter omittingEmptyLines: If `true`, omits empty lines in the
    /// output. Otherwise, all lines are included in the output.
    func joinedLines(omittingEmptyLines: Bool = true) -> String {
        filter { !omittingEmptyLines || !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Returns a string where the elements of the array are joined
    /// by a space character.
    func joinedWords() -> String {
        joined(separator: " ")
    }
}

fileprivate extension String {

    /// Returns an array of strings, where each string represents one line
    /// in the current string.
    func asLines() -> [String] {
        split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
    }

    /// Returns a new string where the provided closure transforms each line.
    /// The closure takes a string representing one line as a parameter.
    /// - Parameter work: The closure that transforms each line.
    func transformingLines(_ work: (String) -> String) -> String {
        asLines().map(work).joinedLines()
    }
}
