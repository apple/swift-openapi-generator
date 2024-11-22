# Frequently asked questions

Review some frequently asked questions below.

## Overview

This article includes some commonly asked questions and answers.

### How do I __ in OpenAPI?

- Review the official [OpenAPI specification](https://spec.openapis.org/oas/v3.1.0).
- Check out the [OpenAPI Guide](https://swagger.io/docs/specification/about/).
- Learn how to achieve common patterns with OpenAPI and Swift OpenAPI Generator at <doc:Useful-OpenAPI-patterns>.

### Why doesn't the generator have feature __?

Check out <doc:Project-scope-and-goals>.

### What OpenAPI features does the generator support?

Check out <doc:Supported-OpenAPI-features>.

### Which underlying HTTP library does the generated code use?

Swift OpenAPI Generator is not tied to any particular HTTP library. Instead, the generated code utilizes a general protocol called [`ClientTransport`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clienttransport) for client code, and [`ServerTransport`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/servertransport) for server code.

The user of the generated code provides one of the concrete transport implementations, based on what's appropriate for their use case.

Swift OpenAPI Generator lists some transport implementations in its [README](https://github.com/apple/swift-openapi-generator#repository-organization), but anyone is welcome to create their own custom transport implementation and share it as a package with the community.

To learn more, check out <doc:Checking-out-an-example-project#Getting-started>, which shows how to use some of the transport implementations.

### How do I customize the HTTP requests and responses?

If the code generated from the OpenAPI document, combined with the concrete transport implementation, doesn't behave exactly as you need, you can provide a _middleware_ type that can inspect and modify the HTTP requests and responses that are passed between the generated code and the transport.

Just like with transports, there are two types, [`ClientMiddleware`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/clientmiddleware) and [`ServerMiddleware`](https://swiftpackageindex.com/apple/swift-openapi-runtime/documentation/openapiruntime/servermiddleware).

To learn more, check out <doc:Checking-out-an-example-project#Middleware> examples.

### Do I commit the generated code to my source repository?

It depends on the way you're integrating Swift OpenAPI Generator.

The recommended way is to use the Swift package plugin, and let the build system generate the code on-demand, without the need to check it into your git repository.

However, if you require to check your generated code into git, you can use the command plugin, or manually invoke the command-line tool.

For details, check out <doc:Manually-invoking-the-generator-CLI>.

### Does regenerating code from an updated OpenAPI document overwrite any of my code?

Swift OpenAPI Generator was designed for a workflow called spec-driven development (check out <doc:Practicing-spec-driven-API-development> for details). That means that it is expected that the OpenAPI document changes frequently, and no developer-written code is overwritten when the Swift code is regenerated from the OpenAPI document.

When run in `client` mode, the generator emits a type called `Client` that conforms to a generated protocol called `APIProtocol`, which defines one method per OpenAPI operation. Client code generation provides you with a concrete implementation that makes HTTP requests over a provided transport. From your code, you _use_ the `Client` type, so when it gets updated, unless the OpenAPI document removed API you're using, you don't need to make any changes to your code.

When run in `server` mode, the generator emits the same `APIProtocol` protocol, and you implement a type that conforms to it, providing one method per OpenAPI operation. The other server generated code takes care of registering the generated routes on the underlying server. That means that when a new operation is added to the OpenAPI document, you get a build error telling you that your custom type needs to implement the new method to conform to `APIProtocol` again, guiding you towards writing code that complies with your OpenAPI document. However, none of your hand-written code is overwritten.

To learn about the different ways of integrating Swift OpenAPI Generator, check out <doc:Manually-invoking-the-generator-CLI>.

### How do I fix the build error "Decl has a package access level but no -package-name was passed"?

The build error `Decl has a package access level but no -package-name was passed` appears when the package or project is not configured with the [`package` access level](https://github.com/apple/swift-evolution/blob/main/proposals/0386-package-access-modifier.md) feature yet.

The cause of this error is that the generated code is using the `package` access modifier for its API, but the project or package are not passing the `-package-name` option to the Swift compiler yet.

For Swift packages, the fix is to ensure your `Package.swift` has a `swift-tools-version` of 5.9 or later.

For Xcode projects, make sure the target that uses the Swift OpenAPI Generator build plugin provides the build setting `SWIFT_PACKAGE_NAME` (called "Package Access Identifier"). Set it to any name, for example the name of your Xcode project.

Alternatively, change the access modifier of the generated code to either `internal` (if no code outside of that module needs to use it) or `public` (if the generated code is exported to other modules and packages.) You can do so by setting `accessModifier: internal` in the generator configuration file, or by providing `--access-modifier internal` to the `swift-openapi-generator` CLI.

For details, check out <doc:Configuring-the-generator>.

### How do I enable the build plugin in Xcode and Xcode Cloud?

By default, you must explicitly enable build plugins before they are allowed to run.

Before a plugin is enabled, you will encounter a build error with the message `"OpenAPIGenerator" is disabled`.

In Xcode, enable the plugin by clicking the "Enable Plugin" button next to the build error and confirm the dialog by clicking "Trust & Enable".

In Xcode Cloud, add the script `ci_scripts/ci_post_clone.sh` next to your Xcode project or workspace, containing:

```bash
#!/usr/bin/env bash

set -e

# NOTE: the misspelling of validation as "validatation" is intentional and the spelling Xcode expects.
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
```

Learn more about Xcode Cloud custom scripts in the [documentation](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts).
