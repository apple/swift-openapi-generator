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

final class StringCodeWriter {
    
    private var lines: [String]
    private var level: Int
    
    convenience init() {
        self.init(level: 0, lines: [])
    }
    
    init(level: Int, lines: [String]) {
        self.level = level
        self.lines = lines
    }
        
    func rendered() -> String {
        lines.joined(separator: "\n")
    }
    
    func writeLines(_ newLines: [String]) {
        newLines.forEach(writeLine)
    }

    func writeLine(_ line: String) {
        let indentation = Array(repeating: "    ", count: level).joined()
        lines.append(indentation + line)
    }
    
    func push() {
        level += 1
    }
    
    func pop() {
        precondition(level > 0, "Cannot pop below 0")
        level -= 1
    }
    
    func withNestedLevel<R>(_ work: () -> R) -> R {
        push()
        defer {
            pop()
        }
        return work()
    }
}

/// A renderer that uses string interpolation and concatenation
/// to convert the provided structure code into raw string form.
struct TextBasedRenderer: RendererProtocol {

    func render(
        structured: StructuredSwiftRepresentation,
        config: Config,
        diagnostics: any DiagnosticCollector
    ) throws -> InMemoryOutputFile {
        let namedFile = structured.file
        renderFile(namedFile.contents)
        let string = writer.rendered()
        return InMemoryOutputFile(
            baseName: namedFile.name,
            contents: Data(string.utf8)
        )
    }
    
    let writer: StringCodeWriter
    
    static var `default`: TextBasedRenderer {
        .init(writer: StringCodeWriter())
    }

    // MARK: - Internals

    /// Renders the specified Swift file.
    func renderFile(_ description: FileDescription) {
        if let topComment = description.topComment {
            renderComment(topComment)
        }
        if let imports = description.imports {
            renderImports(imports)
        }
//        let renderedCodeBlocks = description.codeBlocks
//            .map { renderedCodeBlock($0, level: 0) }
//        for block in renderedCodeBlocks {
//            lines.append(block)
//            lines.append("")
//        }
//        return lines.joinedLines()
    }


    /// Renders the specified comment.
    func renderComment(_ comment: Comment) {
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
        let lines = commentString
            .transformingLines { line in
                if line.isEmpty {
                    return prefix
                }
                return "\(prefix) \(line)"
            }
        writer.writeLines(lines)
    }
    
    /// Renders the specified import statements.
    func renderImports(_ imports: [ImportDescription]?) {
        (imports ?? []).forEach(renderImport)
    }

    /// Renders a single import statement.
    func renderImport(_ description: ImportDescription) {
        func render(preconcurrency: Bool) {
            let spiPrefix = description.spi.map { "@_spi(\($0)) " } ?? ""
            let preconcurrencyPrefix = preconcurrency ? "@preconcurrency " : ""
            if let moduleTypes = description.moduleTypes {
                for type in moduleTypes {
                    writer.writeLine("\(preconcurrencyPrefix)\(spiPrefix)import \(type)")
                }
            } else {
                writer.writeLine("\(preconcurrencyPrefix)\(spiPrefix)import \(description.moduleName)")
            }
        }

        switch description.preconcurrency {
        case .always:
            render(preconcurrency: true)
        case .never:
            render(preconcurrency: false)
        case .onOS(let operatingSystems):
            writer.writeLine("#if \(operatingSystems.map { "os(\($0))" }.joined(separator: " || "))")
            writer.withNestedLevel {
                render(preconcurrency: true)
            }
            writer.writeLine("#else")
            writer.withNestedLevel {
                render(preconcurrency: false)
            }
            writer.writeLine("#endif")
        }
    }

//    /// Renders the specified access modifier.
//    func renderedAccessModifier(_ accessModifier: AccessModifier) -> String {
//        switch accessModifier {
//        case .public:
//            return "public"
//        case .internal:
//            return "internal"
//        case .fileprivate:
//            return "fileprivate"
//        case .private:
//            return "private"
//        }
//    }
//
//    /// Renders the specified identifier.
//    func renderedIdentifier(_ identifier: IdentifierDescription) -> String {
//        switch identifier {
//        case .pattern(let string):
//            return string
//        case .type(let existingTypeDescription):
//            return renderedExistingTypeDescription(existingTypeDescription)
//        }
//    }
//
//    /// Renders the specified member access expression.
//    func renderedMemberAccess(_ memberAccess: MemberAccessDescription) -> String {
//        let left = memberAccess.left.flatMap { renderedExpression($0, level: 0) } ?? ""
//        return "\(left).\(memberAccess.right)"
//    }
//
//    /// Renders the specified function call argument.
//    func renderedFunctionCallArgument(_ arg: FunctionArgumentDescription) -> String {
//        let left = arg.label.flatMap { "\($0): " } ?? ""
//        return left + renderedExpression(arg.expression, level: 0)
//    }
//
//    /// Renders the specified function call.
//    func renderedFunctionCall(_ functionCall: FunctionCallDescription) -> String {
//        let arguments = functionCall.arguments
//        let trailingClosureString: String
//        if let trailingClosure = functionCall.trailingClosure {
//            trailingClosureString = renderedClosureInvocation(trailingClosure, level: 0)
//        } else {
//            trailingClosureString = ""
//        }
//        let expr = renderedExpression(functionCall.calledExpression, level: 0)
//        let args = arguments.map(renderedFunctionCallArgument).joined(separator: ", ")
//        return "\(expr)(\(args))" + trailingClosureString
//    }
//
//    /// Renders the specified assignment expression.
//    func renderedAssignment(_ assignment: AssignmentDescription) -> String {
//        return "\(renderedExpression(assignment.left, level: 0)) = \(renderedExpression(assignment.right, level: 0))"
//    }
//
//    /// Renders the specified switch case kind.
//    func renderedSwitchCaseKind(_ kind: SwitchCaseKind) -> String {
//        switch kind {
//        case let .`case`(expression, associatedValueNames):
//            let associatedValues: String
//            let maybeLet: String
//            if !associatedValueNames.isEmpty {
//                associatedValues = "(" + associatedValueNames.joined(separator: ", ") + ")"
//                maybeLet = "let "
//            } else {
//                associatedValues = ""
//                maybeLet = ""
//            }
//            return "case \(maybeLet)\(renderedExpression(expression, level: 0))\(associatedValues)"
//        case .multiCase(let expressions):
//            let expressions = expressions
//                .map { renderedExpression($0, level: 0) }
//                .joined(separator: ", ")
//            return "case \(expressions)"
//        case .`default`:
//            return "default"
//        }
//    }
//
//    /// Renders the specified switch case.
//    func renderedSwitchCase(_ switchCase: SwitchCaseDescription, level: Int) -> String {
//        var lines: [String] = []
//        lines.append(renderedSwitchCaseKind(switchCase.kind) + ":")
//        lines.append(renderedCodeBlocks(switchCase.body))
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified switch expression.
//    func renderedSwitch(_ switchDesc: SwitchDescription, level: Int) -> String {
//        var lines: [String] = ["switch \(renderedExpression(switchDesc.switchedExpression)) {"]
//        for caseDesc in switchDesc.cases {
//            lines.append(renderedSwitchCase(caseDesc))
//        }
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified if statement.
//    func renderedIf(_ ifDesc: IfStatementDescription, level: Int) -> String {
//        var lines: [String] = []
//        let ifBranch = ifDesc.ifBranch
//        lines.append("if \(renderedExpression(ifBranch.condition)) {")
//        lines.append(renderedCodeBlocks(ifBranch.body))
//        lines.append("}")
//        for branch in ifDesc.elseIfBranches {
//            lines.append("else if \(renderedExpression(branch.condition)) {")
//            lines.append(renderedCodeBlocks(branch.body))
//            lines.append("}")
//        }
//        if let elseBody = ifDesc.elseBody {
//            lines.append("else {")
//            lines.append(renderedCodeBlocks(elseBody))
//            lines.append("}")
//        }
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified switch expression.
//    func renderedDoStatement(_ description: DoStatementDescription, level: Int) -> String {
//        var lines: [String] = ["do {"]
//        lines.append(renderedCodeBlocks(description.doStatement))
//        if let catchBody = description.catchBody {
//            lines.append("} catch {")
//            lines.append(renderedCodeBlocks(catchBody))
//        }
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified value binding expression.
//    func renderedValueBinding(_ valueBinding: ValueBindingDescription) -> String {
//        return "\(renderedBindingKind(valueBinding.kind)) \(renderedFunctionCall(valueBinding.value))"
//    }
//
//    /// Renders the specified keyword.
//    func renderedKeywordKind(_ kind: KeywordKind) -> String {
//        switch kind {
//        case .return:
//            return "return"
//        case .try(hasPostfixQuestionMark: let hasPostfixQuestionMark):
//            return "try\(hasPostfixQuestionMark ? "?" : "")"
//        case .await:
//            return "await"
//        case .throw:
//            return "throw"
//        case .yield:
//            return "yield"
//        }
//    }
//
//    /// Renders the specified unary keyword expression.
//    func renderedUnaryKeywordExpression(_ expression: UnaryKeywordDescription, level: Int) -> String {
//        let keyword = renderedKeywordKind(expression.kind)
//        guard let expr = expression.expression else {
//            return keyword
//        }
//        return "\(keyword) \(renderedExpression(expr))"
//    }
//
//    /// Renders the specified closure invocation.
//    func renderedClosureInvocation(_ invocation: ClosureInvocationDescription, level: Int) -> String {
//        var lines: [String] = []
//        var signatureWords: [String] = ["{"]
//        if !invocation.argumentNames.isEmpty {
//            signatureWords.append(invocation.argumentNames.joined(separator: ", "))
//            signatureWords.append("in")
//        }
//        lines.append(signatureWords.joinedWords())
//        if let body = invocation.body {
//            lines.append(renderedCodeBlocks(body))
//        }
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified binary operator.
//    func renderedBinaryOperator(_ op: BinaryOperator) -> String {
//        op.rawValue
//    }
//
//    /// Renders the specified binary operation.
//    func renderedBinaryOperation(_ operation: BinaryOperationDescription, level: Int) -> String {
//        renderedExpression(operation.left) + " "
//            + renderedBinaryOperator(operation.operation) + " "
//            + renderedExpression(operation.right)
//    }
//
//    /// Renders the specified inout expression.
//    func renderedInOutDescription(_ description: InOutDescription, level: Int) -> String {
//        "&" + renderedExpression(description.referencedExpr)
//    }
//
//    /// Renders the specified optional chaining expression.
//    func renderedOptionalChainingDescription(
//        _ description: OptionalChainingDescription
//    ) -> String {
//        renderedExpression(description.referencedExpr) + "?"
//    }
//
//    /// Renders the specified tuple expression.
//    func renderedTupleDescription(
//        _ description: TupleDescription
//    ) -> String {
//        "(" + description.members.map(renderedExpression).joined(separator: ", ") + ")"
//    }
//
//    /// Renders the specified expression.
//    func renderedExpression(_ expression: Expression, level: Int) -> String {
//        switch expression {
//        case .literal(let literalDescription):
//            return renderedLiteral(literalDescription)
//        case .identifier(let identifierDescription):
//            return renderedIdentifier(identifierDescription)
//        case .memberAccess(let memberAccessDescription):
//            return renderedMemberAccess(memberAccessDescription)
//        case .functionCall(let functionCallDescription):
//            return renderedFunctionCall(functionCallDescription)
//        case .assignment(let assignment):
//            return renderedAssignment(assignment)
//        case .switch(let switchDesc):
//            return renderedSwitch(switchDesc)
//        case .ifStatement(let ifDesc):
//            return renderedIf(ifDesc)
//        case .doStatement(let doStmt):
//            return renderedDoStatement(doStmt)
//        case .valueBinding(let valueBinding):
//            return renderedValueBinding(valueBinding)
//        case .unaryKeyword(let unaryKeyword):
//            return renderedUnaryKeywordExpression(unaryKeyword)
//        case .closureInvocation(let closureInvocation):
//            return renderedClosureInvocation(closureInvocation)
//        case .binaryOperation(let binaryOperation):
//            return renderedBinaryOperation(binaryOperation)
//        case .inOut(let inOut):
//            return renderedInOutDescription(inOut)
//        case .optionalChaining(let optionalChaining):
//            return renderedOptionalChainingDescription(optionalChaining)
//        case .tuple(let tuple):
//            return renderedTupleDescription(tuple)
//        }
//    }
//
//    /// Renders the specified literal expression.
//    func renderedLiteral(_ literal: LiteralDescription) -> String {
//        switch literal {
//        case let .string(string):
//            // Use a raw literal if the string contains a quote/backslash.
//            if string.contains("\"") || string.contains("\\") {
//                return "#\"\(string)\"#"
//            } else {
//                return "\"\(string)\""
//            }
//        case let .int(int):
//            return "\(int)"
//        case let .bool(bool):
//            return bool ? "true" : "false"
//        case .nil:
//            return "nil"
//        case .array(let items):
//            return "[\(items.map { renderedExpression($0) }.joined(separator: ", "))]"
//        }
//    }
//
//    /// Renders the specified where clause requirement.
//    func renderedWhereClauseRequirement(_ requirement: WhereClauseRequirement) -> String {
//        switch requirement {
//        case .conformance(let left, let right):
//            return "\(left): \(right)"
//        }
//    }
//
//    /// Renders the specified where clause.
//    func renderedWhereClause(_ clause: WhereClause) -> String {
//        let renderedRequirements = clause.requirements.map(renderedWhereClauseRequirement)
//        return "where \(renderedRequirements.joined(separator: ", "))"
//    }
//
//    /// Renders the specified extension declaration.
//    func renderedExtension(_ extensionDescription: ExtensionDescription, level: Int) -> String {
//        var signatureWords: [String] = []
//        if let accessModifier = extensionDescription.accessModifier {
//            signatureWords.append(renderedAccessModifier(accessModifier))
//        }
//        signatureWords.append("extension")
//        signatureWords.append(extensionDescription.onType)
//        if !extensionDescription.conformances.isEmpty {
//            signatureWords.append(":")
//            signatureWords.append(extensionDescription.conformances.joined(separator: ", "))
//        }
//        if let whereClause = extensionDescription.whereClause {
//            signatureWords.append(renderedWhereClause(whereClause))
//        }
//        var lines: [String] = []
//        lines.append("\(signatureWords.joinedWords()) {")
//        for declaration in extensionDescription.declarations {
//            lines.append(renderedDeclaration(declaration))
//        }
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified type reference to an existing type.
//    func renderedExistingTypeDescription(_ type: ExistingTypeDescription) -> String {
//        switch type {
//        case .any(let existingTypeDescription):
//            return "any \(renderedExistingTypeDescription(existingTypeDescription))"
//        case .generic(let wrapper, let wrapped):
//            return "\(renderedExistingTypeDescription(wrapper))<\(renderedExistingTypeDescription(wrapped))>"
//        case .optional(let existingTypeDescription):
//            return "\(renderedExistingTypeDescription(existingTypeDescription))?"
//        case .member(let components):
//            return components.joined(separator: ".")
//        case .array(let existingTypeDescription):
//            return "[\(renderedExistingTypeDescription(existingTypeDescription))]"
//        case .dictionaryValue(let existingTypeDescription):
//            return "[String: \(renderedExistingTypeDescription(existingTypeDescription))]"
//        }
//    }
//
//    /// Renders the specified typealias declaration.
//    func renderedTypealias(_ alias: TypealiasDescription) -> String {
//        var words: [String] = []
//        if let accessModifier = alias.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        words.append(contentsOf: [
//            "typealias",
//            alias.name,
//            "=",
//            renderedExistingTypeDescription(alias.existingType),
//        ])
//        return words.joinedWords()
//    }
//
//    /// Renders the specified binding kind.
//    func renderedBindingKind(_ kind: BindingKind) -> String {
//        switch kind {
//        case .var:
//            return "var"
//        case .let:
//            return "let"
//        }
//    }
//
//    /// Renders the specified variable declaration.
//    func renderedVariable(_ variable: VariableDescription, level: Int) -> String {
//        var words: [String] = []
//        if let accessModifier = variable.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        if variable.isStatic {
//            words.append("static")
//        }
//        words.append(renderedBindingKind(variable.kind))
//        let labelWithOptionalType: String
//        if let type = variable.type {
//            labelWithOptionalType = "\(variable.left): \(renderedExistingTypeDescription(type))"
//        } else {
//            labelWithOptionalType = variable.left
//        }
//        words.append(labelWithOptionalType)
//
//        if let right = variable.right {
//            words.append("= \(renderedExpression(right))")
//        }
//
//        var lines: [String] = [words.joinedWords()]
//        if let body = variable.getter {
//            lines.append("{")
//            let hasExplicitGetter = !variable.getterEffects.isEmpty || variable.setter != nil || variable.modify != nil
//            if hasExplicitGetter {
//                lines.append("get \(variable.getterEffects.map(renderedFunctionKeyword).joined(separator: " ")) {")
//            }
//            lines.append(renderedCodeBlocks(body))
//            if hasExplicitGetter {
//                lines.append("}")
//            }
//            if let modify = variable.modify {
//                lines.append("_modify {")
//                lines.append(renderedCodeBlocks(modify))
//                lines.append("}")
//            }
//            if let setter = variable.setter {
//                lines.append("set {")
//                lines.append(renderedCodeBlocks(setter))
//                lines.append("}")
//            }
//            lines.append("}")
//        }
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified struct declaration.
//    func renderedStruct(_ structDesc: StructDescription, level: Int) -> String {
//        var words: [String] = []
//        if let accessModifier = structDesc.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        words.append("struct")
//        words.append(structDesc.name)
//        if !structDesc.conformances.isEmpty {
//            words.append(":")
//            words.append(structDesc.conformances.joined(separator: ", "))
//        }
//        words.append("{")
//        let declarationLine = words.joinedWords()
//
//        var lines: [String] = []
//        lines.append(declarationLine)
//
//        for member in structDesc.members {
//            lines.append(contentsOf: renderedDeclaration(member).asLines())
//        }
//
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified protocol declaration.
//    func renderedProtocol(_ protocolDesc: ProtocolDescription, level: Int) -> String {
//        var words: [String] = []
//        if let accessModifier = protocolDesc.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        words.append("protocol")
//        words.append(protocolDesc.name)
//        if !protocolDesc.conformances.isEmpty {
//            words.append(":")
//            words.append(protocolDesc.conformances.joined(separator: ", "))
//        }
//        words.append("{")
//        let declarationLine = words.joinedWords()
//
//        var lines: [String] = []
//        lines.append(declarationLine)
//
//        for member in protocolDesc.members {
//            lines.append(contentsOf: renderedDeclaration(member).asLines())
//        }
//
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified enum declaration.
//    func renderedEnum(_ enumDesc: EnumDescription, level: Int) -> String {
//        var words: [String] = []
//        if enumDesc.isFrozen {
//            words.append("@frozen")
//        }
//        if let accessModifier = enumDesc.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        if enumDesc.isIndirect {
//            words.append("indirect")
//        }
//        words.append("enum")
//        words.append(enumDesc.name)
//        if !enumDesc.conformances.isEmpty {
//            words.append(":")
//            words.append(enumDesc.conformances.joined(separator: ", "))
//        }
//        words.append("{")
//        let declarationLine = words.joinedWords()
//
//        var lines: [String] = []
//        lines.append(declarationLine)
//
//        for member in enumDesc.members {
//            lines.append(contentsOf: renderedDeclaration(member).asLines())
//        }
//
//        lines.append("}")
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified enum case associated value.
//    func renderedEnumCaseAssociatedValue(_ value: EnumCaseAssociatedValueDescription) -> String {
//        var words: [String] = []
//        if let label = value.label {
//            words.append(label)
//            words.append(":")
//        }
//        words.append(renderedExistingTypeDescription(value.type))
//        return words.joinedWords()
//    }
//
//    /// Renders the specified enum case kind.
//    func renderedEnumCaseKind(_ kind: EnumCaseKind) -> String {
//        switch kind {
//        case .nameOnly:
//            return ""
//        case .nameWithRawValue(let rawValue):
//            return " = \(renderedLiteral(rawValue))"
//        case .nameWithAssociatedValues(let values):
//            if values.isEmpty {
//                return ""
//            }
//            let associatedValues =
//                values
//                .map(renderedEnumCaseAssociatedValue)
//                .joined(separator: ", ")
//            return "(\(associatedValues))"
//        }
//    }
//
//    /// Renders the specified enum case declaration.
//    func renderedEnumCase(_ enumCase: EnumCaseDescription) -> String {
//        return "case \(enumCase.name)\(renderedEnumCaseKind(enumCase.kind))"
//    }
//
//    /// Renders the specified declaration.
//    func renderedDeclaration(_ declaration: Declaration, level: Int) -> String {
//        switch declaration {
//        case let .commentable(comment, nestedDeclaration):
//            return renderedCommentableDeclaration(comment: comment, declaration: nestedDeclaration)
//        case let .deprecated(deprecation, nestedDeclaration):
//            return renderedDeprecatedDeclaration(deprecation: deprecation, declaration: nestedDeclaration)
//        case .variable(let variableDescription):
//            return renderedVariable(variableDescription)
//        case .extension(let extensionDescription):
//            return renderedExtension(extensionDescription)
//        case .struct(let structDescription):
//            return renderedStruct(structDescription)
//        case .protocol(let protocolDescription):
//            return renderedProtocol(protocolDescription)
//        case .enum(let enumDescription):
//            return renderedEnum(enumDescription)
//        case .typealias(let typealiasDescription):
//            return renderedTypealias(typealiasDescription)
//        case .function(let functionDescription):
//            return renderedFunction(functionDescription, level: level)
//        case .enumCase(let enumCase):
//            return renderedEnumCase(enumCase)
//        }
//    }
//
//    /// Renders the specified function kind.
//    func renderedFunctionKind(_ functionKind: FunctionKind) -> String {
//        switch functionKind {
//        case .initializer(let isFailable):
//            return "init\(isFailable ? "?" : "")"
//        case .function(let name, let isStatic):
//            return (isStatic ? "static " : "") + "func \(name)"
//        }
//    }
//
//    /// Renders the specified function keyword.
//    func renderedFunctionKeyword(_ keyword: FunctionKeyword) -> String {
//        switch keyword {
//        case .throws:
//            return "throws"
//        case .async:
//            return "async"
//        }
//    }
//
//    /// Renders the specified function signature.
//    func renderedFunctionSignature(_ signature: FunctionSignatureDescription) -> String {
//        var words: [String] = []
//        if let accessModifier = signature.accessModifier {
//            words.append(renderedAccessModifier(accessModifier))
//        }
//        words.append(renderedFunctionKind(signature.kind))
//        words.append("(")
//        words.append(signature.parameters.map(renderedParameter).joined(separator: ", "))
//        words.append(")")
//        for keyword in signature.keywords {
//            words.append(renderedFunctionKeyword(keyword))
//        }
//        if let returnType = signature.returnType {
//            words.append("->")
//            words.append(renderedExpression(returnType, level: 0))
//        }
//        return words.joinedWords()
//    }
//
//    /// Renders the specified function declaration.
//    func renderedFunction(_ functionDescription: FunctionDescription, level: Int) -> String {
//        var lines: [String] = []
//        var words: [String] = [
//            renderedFunctionSignature(functionDescription.signature)
//        ]
//        if functionDescription.body != nil {
//            words.append("{")
//        }
//        lines.append(words.joinedWords())
//
//        if let body = functionDescription.body {
//            lines.append(contentsOf: body.map { renderedCodeBlock($0, level: level + 1) })
//        }
//
//        if functionDescription.body != nil {
//            lines.append("}")
//        }
//        return lines.joinedLines(level: level)
//    }
//
//    /// Renders the specified parameter declaration.
//    func renderedParameter(_ parameterDescription: ParameterDescription) -> String {
//        var words: [String] = []
//        if let label = parameterDescription.label {
//            words.append(label)
//        } else {
//            words.append("_")
//        }
//        if let name = parameterDescription.name {
//            // If the label and name are the same value, don't repeat it, otherwise
//            // swift-format emits a warning.
//            if name != parameterDescription.label {
//                words.append(name)
//            }
//        }
//        words.append(":")
//        words.append(renderedExistingTypeDescription(parameterDescription.type))
//        if let defaultValue = parameterDescription.defaultValue {
//            words.append("=")
//            words.append(renderedExpression(defaultValue, level: 0))
//        }
//        return words.joinedWords()
//    }
//
//    /// Renders the specified declaration with a comment.
//    func renderedCommentableDeclaration(comment: Comment?, declaration: Declaration, level: Int) -> String {
//        return [
//            comment.map(renderedComment),
//            renderedDeclaration(declaration),
//        ]
//        .compactMap({ $0 }).joinedLines()
//    }
//
//    /// Renders the specified declaration with a deprecation annotation.
//    func renderedDeprecatedDeclaration(deprecation: DeprecationDescription, declaration: Declaration, level: Int) -> String {
//        return [
//            renderedDeprecation(deprecation),
//            renderedDeclaration(declaration),
//        ]
//        .joinedLines()
//    }
//
//    func renderedDeprecation(_ deprecation: DeprecationDescription) -> String {
//        let things: [String] = [
//            "*",
//            "deprecated",
//            deprecation.message.map { "message: \"\($0)\"" },
//            deprecation.renamed.map { "renamed: \"\($0)\"" },
//        ]
//        .compactMap({ $0 })
//        return "@available(\(things.joined(separator: ", ")))"
//    }
//
//    /// Renders the specified code block item.
//    func renderedCodeBlockItem(_ description: CodeBlockItem, level: Int) -> String {
//        switch description {
//        case .declaration(let declaration):
//            return renderedDeclaration(declaration, level: level)
//        case .expression(let expression):
//            return renderedExpression(expression, level: level)
//        }
//    }
//
//    /// Renders the specified code block.
//    func renderedCodeBlock(_ description: CodeBlock, level: Int) -> String {
//        var lines: [String] = []
//        if let comment = description.comment {
//            lines.append(contentsOf: renderedComment(comment, level: level).asLines())
//        }
//        let item = description.item
//        lines.append(contentsOf: renderedCodeBlockItem(item, level: level).asLines())
//        return lines.joinedLines()
//    }
//
//    /// Renders the specified code blocks.
//    func renderedCodeBlocks(
//        _ blocks: [CodeBlock],
//        level: Int
//    ) -> String {
//        blocks.map { renderedCodeBlock($0, level: level) }.joinedLines()
//    }
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
    /// - Returns: A string with the elements of the array joined by newline characters.
    func joinedLines(omittingEmptyLines: Bool = true) -> String {
        filter { !omittingEmptyLines || !$0.isEmpty }
            .joined(separator: "\n")
    }
    
    func joinedLines(level: Int, omittingEmptyLines: Bool = true) -> String {
        filter { !omittingEmptyLines || !$0.isEmpty }
            .map { "\(Array(repeating: "    ", count: level).joined())\($0)" }
            .joined(separator: "\n")
    }

    /// Returns a string where the elements of the array are joined
    /// by a space character.
    /// - Returns: A string with the elements of the array joined by space characters.
    func joinedWords() -> String {
        joined(separator: " ")
    }
}

fileprivate extension String {

    /// Returns an array of strings, where each string represents one line
    /// in the current string.
    /// - Returns: An array of strings, each representing one line in the original string.
    func asLines() -> [String] {
        split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
    }

    /// Returns a new string where the provided closure transforms each line.
    /// The closure takes a string representing one line as a parameter.
    /// - Parameter work: The closure that transforms each line.
    /// - Returns: A new string where each line has been transformed using the given closure.
    func transformingLines(_ work: (String) -> String) -> [String] {
        asLines().map(work)
    }
}
