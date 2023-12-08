# Contributing to Swift OpenAPI Generator

Help improve Swift OpenAPI Generator by implementing a missing feature or fixing a bug.

## Overview

Swift OpenAPI Generator is an open source project that encourages contributions, either to the generator itself, or by building new transport and middleware packages.

> Tip: Unsure whether a missing feature fits into Swift OpenAPI Generator? Check out: <doc:Project-scope-and-goals>.

### Missing transport or middleware

Anyone can create a custom transport or middleware in a new package that depends on the runtime library and provides a type conforming to one of the transport or middleware protocols.

Any adopter of Swift OpenAPI Generator can then depend on that package and use the transport or middleware when creating their client or server.

> Tip: Transport packages for some of the common HTTP client libraries are provided as part of the Swift OpenAPI Generator project. Also check if the community has already created a package that meets your needs.

### Missing or broken feature in the generator

The code generator project is written in Swift and can be thought of as a function that takes an OpenAPI document as input and provides one or more Swift source files as output.

The generated Swift code depends on the runtime library, so some features might require coordinated changes in both the runtime and generator repositories.

Similarly, any changes to the transport and middleware protocols in the runtime library must consider the impact on existing transport and middleware implementation packages.

> Tip: For non-trivial changes affecting the API, consider writing a proposal. For more, check out <doc:Proposals>.

### Testing the generator

The generator relies on a mix of unit and integration tests.

When contributing, consider how the change can be tested and how the tests will be maintained over time.

### Runtime SPI for generated code

The generated code relies on functionality in the runtime library that is not part of its public API. This is provided in an SPI, named `Generated` and is not intended to be used directly by adopters of the generator.

To use this functionality, use an SPI import:

```swift
@_spi(Generated) import OpenAPIRuntime
```

### Example contribution workflow

Let's walk through the steps to implement a missing OpenAPI feature that requires changes in multiple repositories. For example, adding support for a [new query style][0].

1. Clone the generator and runtime repositories and set up a development environment where the generator uses the local runtime package dependency, by either:

    1. Adding both packages to an Xcode workspace; or

    2. Using `swift package edit` to edit the runtime dependency used in the generator package.

2. Run all of the tests in the generator package and make sure they pass, which includes reference tests for the generated code.

3. Update the OpenAPI document in the reference test to use the new OpenAPI feature.

4. Manually update the Swift code in the reference test to include the code you'd like the generator to output.

5. At this point **the reference tests should _fail_**. The differences between the generated code and the desired code are printed in the reference test output.

6. Make incremental changes to the generator and runtime library until the reference tests pass.

7. Once the reference test succeeds, add unit tests for the code you changed.

8. Open pull requests for both the generator and runtime changes and cross-reference them in the pull request descriptions. Note: it's expected that the CI for the generator pull request will fail, because it won't have the changes from the runtime library until the runtime pull request it is merged.

9. One of the project maintainers will review your changes and, once approved, will merge the runtime changes and release a new version of the runtime package.

10. The generator pull request will need to be updated to bump the minimum version of the runtime dependency. At this point the CI should pass and the generator pull request can be merged.

11. All done! Thank you for your contribution! 🙏

[0]: https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md#fixed-fields-10
