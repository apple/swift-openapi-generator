# Examples of using Swift OpenAPI Generator

All the examples are self-contained, so you can copy the package directory of your chosen example and use it as a starter template for your project.

## Getting started

- [`HelloWorldURLSessionClient`](./HelloWorldURLSessionClient) - a URLSession-based CLI client
- [`HelloWorldVaporServer`](./HelloWorldVaporServer) - a Vapor-based CLI server

- [`PostgresDatabaseServer`](./PostgresDatabaseServer) - a server using Postgres for persistent state
- [`RetryingClientMiddleware`](./RetryingClientMiddleware) - a client with a middleware that retries failed requests.

## Deprecated

The following examples will be removed before 1.0.0 is released and is preserved for backwards compatibility with currently published tutorials that point to it.

- [`GreetingService`](./GreetingService) - a Vapor-based CLI server, use `HelloWorldVaporServer` instead
- [`GreetingServiceClient`](./GreetingServiceClient) - a URLSession-based CLI client, use `HelloWorldURLSessionClient` instead
