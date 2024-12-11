# Project scope and goals

Learn about what is in and out of scope of Swift OpenAPI Generator.

## Overview

Swift OpenAPI Generator aims to cover the most commonly used OpenAPI features to simplify your workflow and streamline your codebase. The main goal is to reduce ceremony by generating the repetitive, verbose, and error-prone code associated with encoding API inputs, making HTTP requests, parsing HTTP responses, and decoding the outputs.

> Tip: If you have an idea for a feature to help with this, let us know! See <doc:Contributing-to-Swift-OpenAPI-Generator>.

The goal of the project is to compose with the wider OpenAPI tooling ecosystem so functionality beyond reducing ceremony using code generation is, by default, considered out of scope. When in doubt, file an issue to discuss whether your idea should be a feature of Swift OpenAPI Generator, or fits better as a separate project.

### Guiding principles

#### Principle: Faithfully represent the OpenAPI document

The OpenAPI document is considered as the source of truth. The generator aims to produce code that reflects the document where possible. This includes the specification structure, and the identifiers used by the authors of the OpenAPI document.

As a result, the generated code may not always be idiomatic Swift style or conform to your own custom style guidelines. For example, the API operation identifiers may not be `lowerCamelCase` by default, when using the `defensive` naming strategy. However, an alternative naming strategy called [`idiomatic`](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0013) is available since version 1.6.0 that closer matches Swift conventions.

If you require the generated code to conform to specific style, we recommend you preprocess the OpenAPI document to update the identifiers to produce different code.

For larger documents, you may want to do this programmatically and, if you are doing so in Swift, you could use [OpenAPIKit][0], which is the same library used by Swift OpenAPI Generator.

> Warning: Understand which identifiers can be changed without impacting the wire protocol for the API before attempting to preprocess the OpenAPI document.

#### Principle: Generate code that evolves with the OpenAPI document

As features are added to a service, the OpenAPI document for that service will evolve. The generator aims to produce code that evolves ergonomically as the OpenAPI document evolves.

As a result, the generated code might appear unnecessarily verbose, especially for simple operations.

A concrete example of this is the use of enum types when there is only one documented scenario. This allows for a new enum case to be added to the generated Swift code when a new scenario is added to the OpenAPI document, which results in a better experience for users of the generated code.

Another example is the generation of empty structs within the input or output types. For example, the input type will contain a nested struct for the header fields, even if the API operation has no documented header fields.

#### Principle: Reduce complexity of the generator implementation

Some generators offer lots of options that affect the code generation process. In order to keep the project streamlined and maintainable, Swift OpenAPI Generator offers very few options.

One concrete example of this is that users cannot configure the names of generated types, such as `Client` and `APIProtocol`, and there is no attempt to prevent namespace collisions in the target into which it is generated.

Instead, users are advised to generate code into a dedicated target, and use Swift's module system to separate the generated code from code that depends on it.

Another example is the lack of ability to customize how Swift names are computed from strings provided in the OpenAPI document.

You can read more about this in <doc:API-stability-of-generated-code>.

## See Also

- <doc:Contributing-to-Swift-OpenAPI-Generator>
- <doc:Supported-OpenAPI-features>
- <doc:API-stability-of-generated-code>

[0]: https://github.com/mattpolzin/OpenAPIKit
