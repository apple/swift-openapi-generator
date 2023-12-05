# Examples of using Swift OpenAPI Generator

All the examples are self-contained, so you can copy the package directory of your chosen example and use it as a starter template for your project.

## Getting started

Each of the following packages shows an end-to-end working example with the given transport.

- [`HelloWorldURLSessionClient`](./HelloWorldURLSessionClient) - An URLSession-based CLI client.
- [`HelloWorldAsyncHTTPClientClient`](./HelloWorldAsyncHTTPClientClient) - An AsyncHTTPClient-based CLI client.
- [`HelloWorldVaporServer`](./HelloWorldVaporServer) - A Vapor-based CLI server
- [`HelloWorldHummingbirdServer`](./HelloWorldHummingbirdServer) - A Hummingbird-based CLI server.

## Content types

The following packages show working with various content types, such as JSON, URL-encoded request bodies, plain text, raw bytes, and multipart bodies.

- [`ContentTypesClient`](./ContentTypesClient) - A client showing how to produce and consume the various content types.
- [`ContentTypesServer`](./ContentTypesServer) - A server showing how to produce and consume the various content types.

## Project and target types

The following examples show various ways that Swift OpenAPI Generator can be adopted from a consumer Swift package or an Xcode project.

- [`CommandLineClient`](./CommandLineClient) - A client showing a Swift Argument Parser-based command line tool Swift package.
- [`iOSAppClient`](./iOSAppClient) - An iOS app client that shows how to make calls to the generated code from SwiftUI and how to perform unit and UI testing with a mock client.

## Generator adoption types

The following examples show alternative ways of integrating Swift OpenAPI Generator into your project.

Note that unless specified otherwise, all the examples above use the _build plugin_ to integrate Swift OpenAPI Generator.

- [`CommandPluginClient`](./TODO) TODO
- [`CommandPluginServer`](./TODO) TODO
- [`ManualGeneratorInvocationClient`](./TODO) TODO
- [`ManualGeneratorInvocationServer`](./TODO) TODO

## Deprecated

The following examples will be removed before 1.0.0 is released and is preserved for backwards compatibility with currently published tutorials that point to it.

- [`GreetingService`](./GreetingService) - a Vapor-based CLI server, use `HelloWorldVaporServer` instead
- [`GreetingServiceClient`](./GreetingServiceClient) - a URLSession-based CLI client, use `HelloWorldURLSessionClient` instead
