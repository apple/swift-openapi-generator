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

/// A description of an import declaration.
///
/// For example: `import Foo`.
struct ImportDescription: Equatable, Codable {

    /// The name of the imported module.
    ///
    /// For example, the `Foo` in `import Foo`.
    var moduleName: String

    /// An array of module types imported from the module, if applicable.
    ///
    /// For example, if there are type imports like `import Foo.Bar`, they would be listed here.
    var moduleTypes: [String]?

    /// The name of the private interface for an `@_spi` import.
    ///
    /// For example, if `spi` was "Secret" and the module name was "Foo" then the import
    /// would be `@_spi(Secret) import Foo`.
    var spi: String? = nil

    /// Requirements for the `@preconcurrency` attribute.
    var preconcurrency: PreconcurrencyRequirement = .never

    /// Describes any requirement for the `@preconcurrency` attribute.
    enum PreconcurrencyRequirement: Equatable, Codable {
        /// The attribute is always required.
        case always
        /// The attribute is not required.
        case never
        /// The attribute is required only on the named operating systems.
        case onOS([String])
    }
}

/// A description of an access modifier.
///
/// For example: `public`.
enum AccessModifier: String, Equatable, Codable {

    /// A declaration accessible outside of the module.
    case `public`

    /// A declaration only accessible inside of the module.
    case `internal`

    /// A declaration only accessible inside the same Swift file.
    case `fileprivate`

    /// A declaration only accessible inside the same type or scope.
    case `private`
}

/// A description of a comment.
///
/// For example `/// Hello`.
enum Comment: Equatable, Codable {

    /// An inline comment.
    ///
    /// For example: `// Great code below`.
    case inline(String)

    /// A documentation comment.
    ///
    /// For example: `/// Important type`.
    case doc(String)

    /// A mark comment.
    ///
    /// For example: `// MARK: - Public methods`, with the optional
    /// section break (`-`).
    case mark(String, sectionBreak: Bool)
}

/// A description of a literal.
///
/// For example `"hello"` or `42`.
enum LiteralDescription: Equatable, Codable {

    /// A string literal.
    ///
    /// For example `"hello"`.
    case string(String)

    /// An integer literal.
    ///
    /// For example `42`.
    case int(Int)

    /// A Boolean literal.
    ///
    /// For example `true`.
    case bool(Bool)

    /// The nil literal: `nil`.
    case `nil`

    /// An array literal.
    ///
    /// For example `["hello", 42]`.
    case array([Expression])
}

/// A description of an identifier, such as a variable name.
///
/// For example, in `let foo = 42`, `foo` is an identifier.
struct IdentifierDescription: Equatable, Codable {

    /// The name of the identifier.
    ///
    /// For example, `foo` in `let foo = 42`.
    var name: String
}

/// A description of a member access expression.
///
/// For example `foo.bar`.
struct MemberAccessDescription: Equatable, Codable {

    /// The expression of which a member `right` is accessed.
    ///
    /// For example, in `foo.bar`, `left` represents `foo`.
    var left: Expression?

    /// The member name to access.
    ///
    /// For example, in `foo.bar`, `right` is `bar`.
    var right: String
}

/// A description of a function argument.
///
/// For example in `foo(bar: 42)`, the function argument is `bar: 42`.
struct FunctionArgumentDescription: Equatable, Codable {

    /// An optional label of the function argument.
    ///
    /// For example, in `foo(bar: 42)`, the `label` is `bar`.
    var label: String?

    /// The expression passed as the function argument value.
    ///
    /// For example, in `foo(bar: 42)`, `expression` represents `42`.
    var expression: Expression
}

/// A description of a function call.
///
/// For example `foo(bar: 42)`.
struct FunctionCallDescription: Equatable, Codable {

    /// The expression that returns the function to be called.
    ///
    /// For example, in `foo(bar: 42)`, `calledExpression` represents `foo`.
    var calledExpression: Expression

    /// The arguments to be passed to the function.
    var arguments: [FunctionArgumentDescription] = []

    /// Creates a new function call description.
    /// - Parameters:
    ///   - calledExpression: An expression that returns the function to be called.
    ///   - arguments: Arguments to be passed to the function.
    init(calledExpression: Expression, arguments: [FunctionArgumentDescription] = []) {
        self.calledExpression = calledExpression
        self.arguments = arguments
    }

    /// Creates a new function call description.
    /// - Parameters:
    ///   - calledExpression: An expression that returns the function to be called.
    ///   - arguments: Arguments to be passed to the function.
    init(calledExpression: Expression, arguments: [Expression]) {
        self.init(
            calledExpression: calledExpression,
            arguments: arguments.map { .init(label: nil, expression: $0) }
        )
    }
}

/// A type of a variable binding: `let` or `var`.
enum BindingKind: Equatable, Codable {

    /// A mutable variable.
    case `var`

    /// An immutable variable.
    case `let`
}

/// A description of a variable declaration.
///
/// For example `let foo = 42`.
struct VariableDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier?

    /// A Boolean value that indicates whether the variable is static.
    var isStatic: Bool = false

    /// The variable binding kind.
    var kind: BindingKind

    /// The name of the variable.
    ///
    /// For example, in `let foo = 42`, `left` is `foo`.
    var left: String

    /// The type of the variable.
    ///
    /// For example, in `let foo: Int = 42`, `type` is `Int`.
    var type: String?

    /// The expression to be assigned to the variable.
    ///
    /// For example, in `let foo = 42`, `right` represents `42`.
    var right: Expression? = nil

    /// Body code for the getter.
    ///
    /// For example, in `var foo: Int { 42 }`, `body` represents `{ 42 }`.
    var getter: [CodeBlock]? = nil

    /// Effects for the getter.
    ///
    /// For example, in `var foo: Int { get throws { 42 } }`, effects are `[.throws]`.
    var getterEffects: [FunctionKeyword] = []
}

/// A requirement of a where clause.
enum WhereClauseRequirement: Equatable, Codable {

    /// A conformance requirement.
    ///
    /// For example, in `extension Array where Element: Foo {`, the first tuple value is `Element` and the second `Foo`.
    case conformance(String, String)
}

/// A description of a where clause.
///
/// For example: `extension Array where Element: Foo {`.
struct WhereClause: Equatable, Codable {

    /// One or more requirements to be added after the `where` keyword.
    var requirements: [WhereClauseRequirement]
}

/// A description of an extension declaration.
///
/// For example `extension Foo {`.
struct ExtensionDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier?

    /// The name of the extended type.
    ///
    /// For example, in `extension Foo {`, `onType` is `Foo`.
    var onType: String

    /// Additional type names that the extension conforms to.
    ///
    /// For example: `["Sendable", "Codable"]`.
    var conformances: [String] = []

    /// A where clause constraining the extension declaration.
    var whereClause: WhereClause? = nil

    /// The declarations that the extension adds on the extended type.
    var declarations: [Declaration]
}

/// A description of a struct declaration.
///
/// For example `struct Foo {`.
struct StructDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier? = nil

    /// The name of the struct.
    ///
    /// For example, in `struct Foo {`, `name` is `Foo`.
    var name: String

    /// The type names that the struct conforms to.
    ///
    /// For example: `["Sendable", "Codable"]`.
    var conformances: [String] = []

    /// The declarations that make up the main struct body.
    var members: [Declaration] = []
}

/// A description of an enum declaration.
///
/// For example `enum Bar {`.
struct EnumDescription: Equatable, Codable {

    /// A Boolean value that indicates whether the enum has a `@frozen`
    /// attribute.
    var isFrozen: Bool = false

    /// An access modifier.
    var accessModifier: AccessModifier? = nil

    /// The name of the enum.
    ///
    /// For example, in `enum Bar {`, `name` is `Bar`.
    var name: String

    /// The type names that the enum conforms to.
    ///
    /// For example: `["Sendable", "Codable"]`.
    var conformances: [String] = []

    /// The declarations that make up the enum body.
    var members: [Declaration] = []
}

/// A description of a typealias declaration.
///
/// For example `typealias Foo = Int`.
struct TypealiasDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier?

    /// The name of the typealias.
    ///
    /// For example, in `typealias Foo = Int`, `name` is `Foo`.
    var name: String

    /// The existing type that serves as the underlying type of the alias.
    ///
    /// For example, in `typealias Foo = Int`, `existingType` is `Int`.
    var existingType: String
}

/// A description of a protocol declaration.
///
/// For example `protocol Foo {`.
struct ProtocolDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier? = nil

    /// The name of the protocol.
    ///
    /// For example, in `protocol Foo {`, `name` is `Foo`.
    var name: String

    /// The type names that the protocol conforms to.
    ///
    /// For example: `["Sendable", "Codable"]`.
    var conformances: [String] = []

    /// The function and property declarations that make up the protocol
    /// requirements.
    var members: [Declaration] = []
}

/// A description of a function parameter declaration.
///
/// For example, in `func foo(bar baz: String = "hi")`, the parameter
/// description represents `bar baz: String = "hi"`
struct ParameterDescription: Equatable, Codable {

    /// An external parameter label.
    ///
    /// For example, in `bar baz: String = "hi"`, `label` is `bar`.
    var label: String? = nil

    /// An internal parameter name.
    ///
    /// For example, in `bar baz: String = "hi"`, `name` is `baz`.
    var name: String? = nil

    /// The type name of the parameter.
    ///
    /// For example, in `bar baz: String = "hi"`, `type` is `String`.
    var type: String

    /// A default value of the parameter.
    ///
    /// For example, in `bar baz: String = "hi"`, `defaultValue`
    /// represents `"hi"`.
    var defaultValue: Expression? = nil
}

/// A function kind: `func` or `init`.
enum FunctionKind: Equatable, Codable {

    /// An initializer.
    ///
    /// For example: `init()`, or `init?()` when `failable` is `true`.
    case initializer(failable: Bool)

    /// A function or a method. Can be static.
    ///
    /// For example `foo()`, where `name` is `foo`.
    case function(name: String, isStatic: Bool)
}

/// A function keyword, such as `async` and `throws`.
enum FunctionKeyword: Equatable, Codable {

    /// An asynchronous function.
    case `async`

    /// A function that can throw an error.
    case `throws`
}

/// A description of a function signature.
///
/// For example: `func foo(bar: String) async throws -> Int`.
struct FunctionSignatureDescription: Equatable, Codable {

    /// An access modifier.
    var accessModifier: AccessModifier? = nil

    /// The kind of the function.
    var kind: FunctionKind

    /// The parameters of the function.
    var parameters: [ParameterDescription] = []

    /// The keywords of the function, such as `async` and `throws.`
    var keywords: [FunctionKeyword] = []

    /// The return type name of the function, such as `Int`.
    var returnType: Expression? = nil
}

/// A description of a function definition.
///
/// For example: `func foo() { }`.
struct FunctionDescription: Equatable, Codable {

    /// The signature of the function.
    var signature: FunctionSignatureDescription

    /// The body definition of the function.
    ///
    /// If nil, does not generate `{` and `}` at all for the body scope.
    var body: [CodeBlock]? = nil

    /// Creates a new function description.
    /// - Parameters:
    ///   - signature: The signature of the function.
    ///   - body: The body definition of the function.
    init(signature: FunctionSignatureDescription, body: [CodeBlock]? = nil) {
        self.signature = signature
        self.body = body
    }

    /// Creates a new function description.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - kind: The kind of the function.
    ///   - parameters: The parameters of the function.
    ///   - keywords: The keywords of the function, such as `async`.
    ///   - returnType: The return type name of the function, such as `Int`.
    ///   - body: The body definition of the function.
    init(
        accessModifier: AccessModifier? = nil,
        kind: FunctionKind,
        parameters: [ParameterDescription] = [],
        keywords: [FunctionKeyword] = [],
        returnType: Expression? = nil,
        body: [CodeBlock]? = nil
    ) {
        self.signature = .init(
            accessModifier: accessModifier,
            kind: kind,
            parameters: parameters,
            keywords: keywords,
            returnType: returnType
        )
        self.body = body
    }

    /// Creates a new function description.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - kind: The kind of the function.
    ///   - parameters: The parameters of the function.
    ///   - keywords: The keywords of the function, such as `async`.
    ///   - returnType: The return type name of the function, such as `Int`.
    ///   - body: The body definition of the function.
    init(
        accessModifier: AccessModifier? = nil,
        kind: FunctionKind,
        parameters: [ParameterDescription] = [],
        keywords: [FunctionKeyword] = [],
        returnType: Expression? = nil,
        body: [Expression]
    ) {
        self.init(
            accessModifier: accessModifier,
            kind: kind,
            parameters: parameters,
            keywords: keywords,
            returnType: returnType,
            body: body.map { .expression($0) }
        )
    }
}

/// A description of the associated value of an enum case.
///
/// For example, in `case foo(bar: String)`, the associated value
/// represents `bar: String`.
struct EnumCaseAssociatedValueDescription: Equatable, Codable {

    /// A variable label.
    ///
    /// For example, in `bar: String`, `label` is `bar`.
    var label: String?

    /// A variable type name.
    ///
    /// For example, in `bar: String`, `type` is `String`.
    var type: String
}

/// An enum case kind.
///
/// For example: `case foo` versus `case foo(String)`, and so on.
enum EnumCaseKind: Equatable, Codable {

    /// A case with only a name.
    ///
    /// For example: `case foo`.
    case nameOnly

    /// A case with a name and a raw value.
    ///
    /// For example: `case foo = "Foo"`.
    case nameWithRawValue(LiteralDescription)

    /// A case with a name and associated values.
    ///
    /// For example: `case foo(String)`.
    case nameWithAssociatedValues([EnumCaseAssociatedValueDescription])
}

/// A description of an enum case.
///
/// For example: `case foo(String)`.
struct EnumCaseDescription: Equatable, Codable {

    /// The name of the enum case.
    ///
    /// For example, in `case foo`, `name` is `foo`.
    var name: String

    /// The kind of the enum case.
    var kind: EnumCaseKind = .nameOnly
}

/// A declaration of a Swift entity.
indirect enum Declaration: Equatable, Codable {

    /// A declaration that adds a comment on top of the provided declaration.
    case commentable(Comment?, Declaration)

    /// A declaration that adds a comment on top of the provided declaration.
    case deprecated(DeprecationDescription, Declaration)

    /// A variable declaration.
    case variable(VariableDescription)

    /// An extension declaration.
    case `extension`(ExtensionDescription)

    /// A struct declaration.
    case `struct`(StructDescription)

    /// An enum declaration.
    case `enum`(EnumDescription)

    /// A typealias declaration.
    case `typealias`(TypealiasDescription)

    /// A protocol declaration.
    case `protocol`(ProtocolDescription)

    /// A function declaration.
    case function(FunctionDescription)

    /// An enum case declaration.
    case enumCase(EnumCaseDescription)
}

/// A description of a deprecation notice.
///
/// For example: `@available(*, deprecated, message: "This is going away", renamed: "other(param:)")`
struct DeprecationDescription: Equatable, Codable {

    /// A message used by the deprecation attribute.
    var message: String?

    /// A new name of the symbol, allowing the user to get a fix-it.
    var renamed: String?
}

/// A description of an assignment expression.
///
/// For example: `foo = 42`.
struct AssignmentDescription: Equatable, Codable {

    /// The left-hand side expression, the variable to assign to.
    ///
    /// For example, in `foo = 42`, `left` is `foo`.
    var left: Expression

    /// The right-hand side expression, the value to assign.
    ///
    /// For example, in `foo = 42`, `right` is `42`.
    var right: Expression
}

/// A switch case kind, either a `case` or a `default`.
enum SwitchCaseKind: Equatable, Codable {

    /// A case.
    ///
    /// For example: `case let foo(bar):`.
    case `case`(Expression, [String])

    /// A case with multiple comma-separated expressions.
    ///
    /// For example: `case "foo", "bar":`.
    case multiCase([Expression])

    /// A default. Spelled as `default:`.
    case `default`
}

/// A description of a switch case definition.
///
/// For example: `case foo: print("foo")`.
struct SwitchCaseDescription: Equatable, Codable {

    /// The kind of the switch case.
    var kind: SwitchCaseKind

    /// The body of the switch case.
    ///
    /// For example, in `case foo: print("foo")`, `body`
    /// represents `print("foo")`.
    var body: [CodeBlock]
}

/// A description of a switch statement expression.
///
/// For example: `switch foo {`.
struct SwitchDescription: Equatable, Codable {

    /// The expression evaluated by the switch statement.
    ///
    /// For example, in `switch foo {`, `switchedExpression` is `foo`.
    var switchedExpression: Expression

    /// The cases defined in the switch statement.
    var cases: [SwitchCaseDescription]
}

/// A description of an if branch and the corresponding code block.
///
/// For example: in `if foo { bar }`, the condition pair represents
/// `foo` + `bar`.
struct IfBranch: Equatable, Codable {

    /// The expressions evaluated by the if statement and their corresponding
    /// body blocks. If more than one is provided, an `else if` branch is added.
    ///
    /// For example, in `if foo { bar }`, `condition` is `foo`.
    var condition: Expression

    /// The body executed if the `condition` evaluates to true.
    ///
    /// For example, in `if foo { bar }`, `body` is `bar`.
    var body: [CodeBlock]
}

/// A description of an if[[/elseif]/else] statement expression.
///
/// For example: `if foo { } else if bar { } else { }`.
struct IfStatementDescription: Equatable, Codable {

    /// The primary `if` branch.
    var ifBranch: IfBranch

    /// Additional `else if` branches.
    var elseIfBranches: [IfBranch]

    /// The body of an else block.
    ///
    /// No `else` statement is added when `elseBody` is nil.
    var elseBody: [CodeBlock]?
}

/// A description of a do statement.
///
/// For example: `do { try foo() } catch { return bar }`.
struct DoStatementDescription: Equatable, Codable {

    /// The code blocks in the `do` statement body.
    ///
    /// For example, in `do { try foo() } catch { return bar }`,
    /// `doBody` is `try foo()`.
    var doStatement: [CodeBlock]

    /// The code blocks in the `catch` statement.
    ///
    /// If nil, no `catch` statement is added.
    ///
    /// For example, in `do { try foo() } catch { return bar }`,
    /// `catchBody` is `return bar`.
    var catchBody: [CodeBlock]?
}

/// A description of a value binding used in enums with associated values.
///
/// For example: `let foo(bar)`.
struct ValueBindingDescription: Equatable, Codable {

    /// The binding kind: `let` or `var`.
    var kind: BindingKind

    /// The bound values in a function call expression syntax.
    ///
    /// For example, in `let foo(bar)`, `value` represents `foo(bar)`.
    var value: FunctionCallDescription
}

/// A kind of a keyword.
enum KeywordKind: Equatable, Codable {

    /// The return keyword.
    case `return`

    /// The try keyword.
    case `try`(hasPostfixQuestionMark: Bool)

    /// The await keyword.
    case `await`

    /// The throw keyword.
    case `throw`
}

/// A description of an expression that places a keyword before an expression.
struct UnaryKeywordDescription: Equatable, Codable {

    /// The keyword to place before the expression.
    ///
    /// For example, in `return foo`, `kind` represents `return`.
    var kind: KeywordKind

    /// The expression prefixed by the keyword.
    ///
    /// For example, in `return foo`, `expression` represents `foo`.
    var expression: Expression? = nil
}

/// A description of a closure invocation.
///
/// For example: `{ foo in return foo + "bar" }`.
struct ClosureInvocationDescription: Equatable, Codable {

    /// The names of the arguments taken by the closure.
    ///
    /// For example, in `{ foo in return foo + "bar" }`, `argumentNames`
    /// is `["foo"]`.
    var argumentNames: [String] = []

    /// The code blocks of the closure body.
    ///
    /// For example, in `{ foo in return foo + "bar" }`, `body`
    /// represents `return foo + "bar"`.
    var body: [CodeBlock]? = nil
}

/// A binary operator.
///
/// For example: `+=` in `a += b`.
enum BinaryOperator: String, Equatable, Codable {

    /// The += operator, adds and then assigns another value.
    case plusEquals = "+="

    /// The == operator, checks equality between two values.
    case equals = "=="

    /// The ... operator, creates an end-inclusive range between two numbers.
    case rangeInclusive = "..."

    /// The || operator, used between two Boolean values.
    case booleanOr = "||"
}

/// A description of a binary operation expression.
///
/// For example: `foo += 1`.
struct BinaryOperationDescription: Equatable, Codable {

    /// The left-hand side expression of the operation.
    ///
    /// For example, in `foo += 1`, `left` is `foo`.
    var left: Expression

    /// The binary operator tying the two expressions together.
    ///
    /// For example, in `foo += 1`, `operation` represents `+=`.
    var operation: BinaryOperator

    /// The right-hand side expression of the operation.
    ///
    /// For example, in `foo += 1`, `right` is `1`.
    var right: Expression
}

/// A description of an inout expression, which provides a read-write
/// reference to a variable.
///
/// For example, `&foo` passes a reference to the `foo` variable.
struct InOutDescription: Equatable, Codable {

    /// The referenced expression.
    ///
    /// For example, in `&foo`, `referencedExpr` is `foo`.
    var referencedExpr: Expression
}

/// A description of an optional chaining expression.
///
/// For example, in `foo?`, `referencedExpr` is `foo`.
struct OptionalChainingDescription: Equatable, Codable {

    /// The referenced expression.
    ///
    /// For example, in `foo?`, `referencedExpr` is `foo`.
    var referencedExpr: Expression
}

/// A description of a tuple.
///
/// For example: `(foo, bar)`.
struct TupleDescription: Equatable, Codable {

    /// The member expressions.
    ///
    /// For example, in `(foo, bar)`, `members` is `[foo, bar]`.
    var members: [Expression]
}

/// A Swift expression.
indirect enum Expression: Equatable, Codable {

    /// A literal.
    ///
    /// For example `"hello"` or `42`.
    case literal(LiteralDescription)

    /// An identifier, such as a variable name.
    ///
    /// For example, in `let foo = 42`, `foo` is an identifier.
    case identifier(IdentifierDescription)

    /// A member access expression.
    ///
    /// For example: `foo.bar`.
    case memberAccess(MemberAccessDescription)

    /// A function call.
    ///
    /// For example: `foo(bar: 42)`.
    case functionCall(FunctionCallDescription)

    /// An assignment expression.
    ///
    /// For example `foo = 42`.
    case assignment(AssignmentDescription)

    /// A switch statement expression.
    ///
    /// For example: `switch foo {`.
    case `switch`(SwitchDescription)

    /// An if statement, with optional else if's and an else statement attached.
    ///
    /// For example: `if foo { bar } else if baz { boo } else { bam }`.
    case ifStatement(IfStatementDescription)

    /// A do statement.
    ///
    /// For example: `do { try foo() } catch { return bar }`.
    case doStatement(DoStatementDescription)

    /// A value binding used in enums with associated values.
    ///
    /// For example: `let foo(bar)`.
    case valueBinding(ValueBindingDescription)

    /// An expression that places a keyword before an expression.
    case unaryKeyword(UnaryKeywordDescription)

    /// A closure invocation.
    ///
    /// For example: `{ foo in return foo + "bar" }`.
    case closureInvocation(ClosureInvocationDescription)

    /// A binary operation expression.
    ///
    /// For example: `foo += 1`.
    case binaryOperation(BinaryOperationDescription)

    /// An inout expression, which provides a reference to a variable.
    ///
    /// For example, `&foo` passes a reference to the `foo` variable.
    case inOut(InOutDescription)

    /// An optional chaining expression.
    ///
    /// For example, in `foo?`, `referencedExpr` is `foo`.
    case optionalChaining(OptionalChainingDescription)

    /// A tuple expression.
    ///
    /// For example: `(foo, bar)`.
    case tuple(TupleDescription)
}

/// A code block item, either a declaration or an expression.
enum CodeBlockItem: Equatable, Codable {

    /// A declaration, such as of a new type or function.
    case declaration(Declaration)

    /// An expression, such as a call of a declared function.
    case expression(Expression)
}

/// A code block, with an optional comment.
struct CodeBlock: Equatable, Codable {

    /// The comment to prepend to the code block item.
    var comment: Comment?

    /// The code block item that appears below the comment.
    var item: CodeBlockItem
}

/// A description of a Swift file.
struct FileDescription: Equatable, Codable {

    /// A comment placed at the top of the file.
    var topComment: Comment?

    /// Import statements placed below the top comment, but before the code
    /// blocks.
    var imports: [ImportDescription]?

    /// The code blocks that represent the main contents of the file.
    var codeBlocks: [CodeBlock]
}

/// A description of a named Swift file.
struct NamedFileDescription: Equatable, Codable {

    /// A file name, including the file extension.
    ///
    /// For example: `Foo.swift`.
    var name: String

    /// The contents of the file.
    var contents: FileDescription
}

/// A file with contents made up of structured Swift code.
struct StructuredSwiftRepresentation: Equatable, Codable {

    /// The contents of the file.
    var file: NamedFileDescription
}

// MARK: - Conveniences

extension Declaration {

    /// A variable declaration.
    ///
    /// For example: `let foo = 42`.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - isStatic: A Boolean value that indicates whether the variable
    ///   is static.
    ///   - kind: The variable binding kind.
    ///   - left: The name of the variable.
    ///   - type: The type of the variable.
    ///   - right: The expression to be assigned to the variable.
    ///   - getter: Body code for the getter of the variable.
    ///   - getterEffects: Effects of the getter.
    /// - Returns: Variable declaration.
    static func variable(
        accessModifier: AccessModifier? = nil,
        isStatic: Bool = false,
        kind: BindingKind,
        left: String,
        type: String? = nil,
        right: Expression? = nil,
        getter: [CodeBlock]? = nil,
        getterEffects: [FunctionKeyword] = []
    ) -> Self {
        .variable(
            .init(
                accessModifier: accessModifier,
                isStatic: isStatic,
                kind: kind,
                left: left,
                type: type,
                right: right,
                getter: getter,
                getterEffects: getterEffects
            )
        )
    }

    /// A description of an enum case.
    ///
    /// For example: `case foo(String)`.
    /// - Parameters:
    ///   - name: The name of the enum case.
    ///   - kind: The kind of the enum case.
    /// - Returns: An enum case declaration.
    static func enumCase(
        name: String,
        kind: EnumCaseKind = .nameOnly
    ) -> Self {
        .enumCase(.init(name: name, kind: kind))
    }

    /// A description of a typealias declaration.
    ///
    /// For example `typealias Foo = Int`.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - name: The name of the typealias.
    ///   - existingType: The existing type that serves as the
    ///   underlying type of the alias.
    /// - Returns: A typealias declaration.
    static func `typealias`(
        accessModifier: AccessModifier? = nil,
        name: String,
        existingType: String
    ) -> Self {
        .typealias(
            .init(
                accessModifier: accessModifier,
                name: name,
                existingType: existingType
            )
        )
    }

    /// A description of a function definition.
    ///
    /// For example: `func foo() { }`.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - kind: The kind of the function.
    ///   - parameters: The parameters of the function.
    ///   - keywords: The keywords of the function, such as `async` and
    ///   `throws.`
    ///   - returnType: The return type name of the function, such as `Int`.
    ///   - body: The body definition of the function.
    /// - Returns: A function declaration.
    static func function(
        accessModifier: AccessModifier? = nil,
        kind: FunctionKind,
        parameters: [ParameterDescription],
        keywords: [FunctionKeyword] = [],
        returnType: Expression? = nil,
        body: [CodeBlock]? = nil
    ) -> Self {
        .function(
            .init(
                accessModifier: accessModifier,
                kind: kind,
                parameters: parameters,
                keywords: keywords,
                returnType: returnType,
                body: body
            )
        )
    }

    /// A description of a function definition.
    ///
    /// For example: `func foo() { }`.
    /// - Parameters:
    ///   - signature: The signature of the function.
    ///   - body: The body definition of the function.
    /// - Returns: A function declaration.
    static func function(
        signature: FunctionSignatureDescription,
        body: [CodeBlock]? = nil
    ) -> Self {
        .function(
            .init(
                signature: signature,
                body: body
            )
        )
    }

    /// A description of an enum declaration.
    ///
    /// For example `enum Bar {`.
    /// - Parameters:
    ///   - isFrozen: A Boolean value that indicates whether the enum has
    ///   a `@frozen` attribute.
    ///   - accessModifier: An access modifier.
    ///   - name: The name of the enum.
    ///   - conformances: The type names that the enum conforms to.
    ///   - members: The declarations that make up the enum body.
    /// - Returns: An enum declaration.
    static func `enum`(
        isFrozen: Bool = false,
        accessModifier: AccessModifier? = nil,
        name: String,
        conformances: [String] = [],
        members: [Declaration] = []
    ) -> Self {
        .enum(
            .init(
                isFrozen: isFrozen,
                accessModifier: accessModifier,
                name: name,
                conformances: conformances,
                members: members
            )
        )
    }

    /// A description of an extension declaration.
    ///
    /// For example `extension Foo {`.
    /// - Parameters:
    ///   - accessModifier: An access modifier.
    ///   - onType: The name of the extended type.
    ///   - conformances: Additional type names that the extension conforms to.
    ///   - whereClause: A where clause constraining the extension declaration.
    ///   - declarations: The declarations that the extension adds on the
    ///   extended type.
    /// - Returns: An extension declaration.
    static func `extension`(
        accessModifier: AccessModifier?,
        onType: String,
        conformances: [String] = [],
        whereClause: WhereClause? = nil,
        declarations: [Declaration]
    ) -> Self {
        .extension(
            .init(
                accessModifier: accessModifier,
                onType: onType,
                conformances: conformances,
                whereClause: whereClause,
                declarations: declarations
            )
        )
    }
}

extension IdentifierDescription: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(name: value)
    }
}

extension FunctionKind {
    /// Returns a non-failable initializer, for example `init()`.
    static var initializer: Self {
        return .initializer(failable: false)
    }

    /// Returns a non-static function kind.
    static func function(name: String) -> Self {
        .function(name: name, isStatic: false)
    }
}

extension CodeBlock {

    /// Returns a new declaration code block wrapping the provided declaration.
    /// - Parameter declaration: The declaration to wrap.
    static func declaration(_ declaration: Declaration) -> Self {
        return CodeBlock(item: .declaration(declaration))
    }

    /// Returns a new expression code block wrapping the provided expression.
    /// - Parameter expression: The expression to wrap.
    static func expression(_ expression: Expression) -> Self {
        return CodeBlock(item: .expression(expression))
    }
}

extension Expression {

    /// A string literal.
    ///
    /// For example: `"hello"`.
    /// - Parameter value: The string value of the literal.
    static func literal(_ value: String) -> Self {
        .literal(.string(value))
    }

    /// An integer literal.
    ///
    /// For example `42`.
    /// - Parameter value: The integer value of the literal.
    static func literal(_ value: Int) -> Self {
        .literal(.int(value))
    }

    /// Returns a new expression that accesses the member on the current
    /// expression.
    /// - Parameter member: The name of the member to access on the expression.
    func dot(_ member: String) -> Expression {
        return .memberAccess(.init(left: self, right: member))
    }

    /// Returns a new expression that calls the current expression as a function
    /// with the specified arguments.
    /// - Parameter arguments: The arguments used to call the expression.
    func call(_ arguments: [FunctionArgumentDescription]) -> Expression {
        .functionCall(.init(calledExpression: self, arguments: arguments))
    }

    /// Returns a new member access expression without a receiver,
    /// starting with dot.
    ///
    /// For example: `.foo`, where `member` is `foo`.
    /// - Parameter member: The name of the member to access.
    static func dot(_ member: String) -> Self {
        return Self.memberAccess(.init(right: member))
    }

    /// Returns a new identifier expression for the provided name.
    /// - Parameter name: The name of the identifier.
    static func identifier(_ name: String) -> Self {
        .identifier(.init(name: name))
    }

    /// Returns a new switch statement expression.
    /// - Parameters:
    ///   - switchedExpression: The expression evaluated by the switch
    ///    statement.
    ///   - cases: The cases defined in the switch statement.
    static func `switch`(
        switchedExpression: Expression,
        cases: [SwitchCaseDescription]
    ) -> Self {
        .`switch`(
            .init(
                switchedExpression: switchedExpression,
                cases: cases
            )
        )
    }

    /// Returns an if statement, with optional else if's and an else
    /// statement attached.
    /// - Parameters:
    ///   - ifBranch: The primary `if` branch.
    ///   - elseIfBranches: Additional `else if` branches.
    ///   - elseBody: The body of an else block.
    static func ifStatement(
        ifBranch: IfBranch,
        elseIfBranches: [IfBranch] = [],
        elseBody: [CodeBlock]? = nil
    ) -> Self {
        .ifStatement(
            .init(
                ifBranch: ifBranch,
                elseIfBranches: elseIfBranches,
                elseBody: elseBody
            )
        )
    }

    /// Returns a new function call expression.
    ///
    /// For example `foo(bar: 42)`.
    /// - Parameters:
    ///   - calledExpression: The expression to be called as a function.
    ///   - arguments: The arguments to be passed to the function call.
    static func functionCall(
        calledExpression: Expression,
        arguments: [FunctionArgumentDescription] = []
    ) -> Self {
        .functionCall(
            .init(
                calledExpression: calledExpression,
                arguments: arguments
            )
        )
    }

    /// Returns a new function call expression.
    ///
    /// For example: `foo(bar: 42)`.
    /// - Parameters:
    ///   - calledExpression: The expression called as a function.
    ///   - arguments: The arguments passed to the function call.
    static func functionCall(
        calledExpression: Expression,
        arguments: [Expression]
    ) -> Self {
        .functionCall(
            .init(
                calledExpression: calledExpression,
                arguments: arguments.map { .init(label: nil, expression: $0) }
            )
        )
    }

    /// Returns a new expression that places a keyword before an expression.
    /// - Parameters:
    ///   - kind: The keyword to place before the expression.
    ///   - expression: The expression prefixed by the keyword.
    static func unaryKeyword(
        kind: KeywordKind,
        expression: Expression? = nil
    ) -> Self {
        .unaryKeyword(.init(kind: kind, expression: expression))
    }

    /// Returns a new expression that puts the return keyword before
    /// an expression.
    /// - Parameter expression: The expression to prepend.
    static func `return`(_ expression: Expression? = nil) -> Self {
        .unaryKeyword(kind: .return, expression: expression)
    }

    /// Returns a new expression that puts the try keyword before
    /// an expression.
    /// - Parameter expression: The expression to prepend.
    static func `try`(_ expression: Expression) -> Self {
        .unaryKeyword(kind: .try, expression: expression)
    }

    /// Returns a new expression that puts the try? keyword before
    /// an expression.
    /// - Parameter expression: The expression to prepend.
    static func optionalTry(_ expression: Expression) -> Self {
        .unaryKeyword(
            kind: .try(hasPostfixQuestionMark: true),
            expression: expression
        )
    }

    /// Returns a new expression that puts the await keyword before
    /// an expression.
    /// - Parameter expression: The expression to prepend.
    static func `await`(_ expression: Expression) -> Self {
        .unaryKeyword(kind: .await, expression: expression)
    }

    /// Returns a new value binding used in enums with associated values.
    ///
    /// For example: `let foo(bar)`.
    /// - Parameters:
    ///   - kind: The binding kind: `let` or `var`.
    ///   - value: The bound values in a function call expression syntax.
    static func valueBinding(
        kind: BindingKind,
        value: FunctionCallDescription
    ) -> Self {
        .valueBinding(.init(kind: kind, value: value))
    }

    /// Returns a new closure invocation expression.
    ///
    /// For example: such as `{ foo in return foo + "bar" }`.
    /// - Parameters:
    ///   - argumentNames: The names of the arguments taken by the closure.
    ///   - body: The code blocks of the closure body.
    static func `closureInvocation`(
        argumentNames: [String] = [],
        body: [CodeBlock]? = nil
    ) -> Self {
        .closureInvocation(.init(argumentNames: argumentNames, body: body))
    }

    /// Creates a new binary operation expression.
    ///
    /// For example: `foo += 1`.
    /// - Parameters:
    ///   - left: The left-hand side expression of the operation.
    ///   - operation: The binary operator tying the two expressions together.
    ///   - right: The right-hand side expression of the operation.
    static func `binaryOperation`(
        left: Expression,
        operation: BinaryOperator,
        right: Expression
    ) -> Self {
        .binaryOperation(.init(left: left, operation: operation, right: right))
    }

    /// Creates a new inout expression, which provides a read-write
    /// reference to a variable.
    ///
    /// For example, `&foo` passes a reference to the `foo` variable.
    /// - Parameter referencedExpr: The referenced expression.
    static func inOut(_ referencedExpr: Expression) -> Self {
        .inOut(.init(referencedExpr: referencedExpr))
    }

    /// Creates a new assignment expression.
    ///
    /// For example: `foo = 42`.
    /// - Parameters:
    ///   - left: The left-hand side expression, the variable to assign to.
    ///   - right: The right-hand side expression, the value to assign.
    /// - Returns: Assignment expression.
    static func assignment(left: Expression, right: Expression) -> Self {
        .assignment(.init(left: left, right: right))
    }

    /// Returns a new optional chaining expression wrapping the current
    /// expression.
    ///
    /// For example, for the current expression `foo`, returns `foo?`.
    func optionallyChained() -> Self {
        .optionalChaining(.init(referencedExpr: self))
    }

    /// Returns a new tuple expression.
    ///
    /// For example, in `(foo, bar)`, `members` is `[foo, bar]`.
    /// - Parameter expressions: The member expressions.
    /// - Returns: A tuple expression.
    static func tuple(_ expressions: [Expression]) -> Self {
        .tuple(.init(members: expressions))
    }
}

extension MemberAccessDescription {
    /// Creates a new member access expression without a receiver, starting
    /// with dot.
    ///
    /// For example, `.foo`, where `member` is `foo`.
    /// - Parameter member: The name of the member to access.
    static func dot(_ member: String) -> Self {
        .init(right: member)
    }
}

extension Expression: ExpressibleByStringLiteral, ExpressibleByNilLiteral, ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Expression...) {
        self = .literal(.array(elements))
    }

    init(stringLiteral value: String) {
        self = .literal(.string(value))
    }

    init(nilLiteral: ()) {
        self = .literal(.nil)
    }
}

extension LiteralDescription: ExpressibleByStringLiteral, ExpressibleByNilLiteral, ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Expression...) {
        self = .array(elements)
    }

    init(stringLiteral value: String) {
        self = .string(value)
    }

    init(nilLiteral: ()) {
        self = .nil
    }
}

extension VariableDescription {

    /// Returns a new mutable variable declaration.
    ///
    /// For example `var foo = 42`.
    /// - Parameter name: The name of the variable.
    static func `var`(_ name: String) -> Self {
        Self.init(kind: .var, left: name)
    }

    /// Returns a new immutable variable declaration.
    ///
    /// For example `let foo = 42`.
    /// - Parameter name: The name of the variable.
    static func `let`(_ name: String) -> Self {
        Self.init(kind: .let, left: name)
    }
}

extension Expression {

    /// Creates a new assignment description where the called expression is
    /// assigned the value of the specified expression.
    /// - Parameter rhs: The right-hand side of the assignment expression.
    func equals(_ rhs: Expression) -> AssignmentDescription {
        .init(left: self, right: rhs)
    }
}

extension FunctionArgumentDescription: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self = .init(expression: .literal(.string(value)))
    }
}

extension FunctionSignatureDescription {
    /// Returns a new function signature description that has the access
    /// modifier updated to the specified one.
    /// - Parameter accessModifier: The access modifier to use.
    func withAccessModifier(_ accessModifier: AccessModifier?) -> Self {
        var value = self
        value.accessModifier = accessModifier
        return value
    }
}

extension SwitchCaseKind {
    /// Returns a new switch case kind with no argument names, only the
    /// specified expression as the name.
    /// - Parameter expression: The expression for the switch case label.
    static func `case`(_ expression: Expression) -> Self {
        .case(expression, [])
    }
}

extension KeywordKind {

    /// Returns the try keyword without the postfix question mark.
    static var `try`: Self {
        .try(hasPostfixQuestionMark: false)
    }
}

extension Declaration {
    /// Returns a new deprecated variant of the declaration if `shouldDeprecate` is true.
    func deprecate(if shouldDeprecate: Bool) -> Self {
        if shouldDeprecate {
            return .deprecated(.init(), self)
        }
        return self
    }
}
