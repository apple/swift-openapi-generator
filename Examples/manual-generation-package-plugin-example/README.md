# Manual code generation using the Swift package plugin

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A command-line tool that uses a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

It shows using the command plugin manually instead of using either the build plugin or invoking the command-line tool manually.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

The server can be started by running any of the Hello World server examples locally.

## Regenerate code

Whenever the `openapi.yaml` document changes, rerun the code generation:

```console
% swift package generate-code-from-openapi
Plugin ‘OpenAPIGeneratorCommand’ wants permission to write to the package directory.
Stated reason: “To write the generated Swift files back into the source directory of the package.”.
Allow this plugin to write to the package directory? (yes/no) yes
...
✅ OpenAPI code generation for target 'CommandPluginInvocationClient' successfully completed.
```

And then check in the changed files in `./Sources/CommandPluginInvocationClient/GeneratedSources/*`.

## Usage

Build and run the client CLI using:

```console
% swift run
Hello, Stranger!
```
