# Hello World iOS client app

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

An iOS app that shows using a generated client to make a request to the Greeting Service running on `http://localhost:8080`.

The tool uses the [URLSession](https://developer.apple.com/documentation/foundation/urlsession) API to perform the HTTP call, wrapped in the [Swift OpenAPI URLSession Transport](https://github.com/apple/swift-openapi-urlsession).

## Important

The configuration file overrides the `accessModifier` to be `internal`, since the generated code is placed directly into the iOS app target.

If you split the generated code into a separate library, such as a framework or a SwiftPM library product, you also need to change the `accessModifier` to either `public` or `package`.

If you use `package`, also add the `SWIFT_PACKAGE_NAME` build setting to your project, and set it to any name you like, for example matching the name of your project. If you don't set the build setting, you'll get the build error "Decl has a package access level but no -package-name was passed".

## Usage

The server can be started by running any of the Hello World server examples locally.

Open the project in Xcode and run the iOS app on a Simulator, to allow it to connect to your local server.

## Testing

The unit tests verify that the `MockClient` works as expected.

You can provide `MockClient` to any API that accepts a value of `any APIProtocol` (as opposed to the concrete `Client` type, which conforms to the `APIProtocol`). This way, you control how the mock server responds to requests, allowing you to simulate all conditions, including failures.

The UI tests use the environment variable `USE_MOCK_CLIENT` to tell the app to use the mock client as well. You can skip passing that environment variable, however then your UI tests will require that a local `GreetingService` server is running locally whenever your UI tests run, which can be impractical. 
