# Integration Test

A Swift package used as an integration test in the Swift OpenAPI Generator ecosystem.

## Usage

This package can be used when testing changes in another project. 

For example, from the pull request pipeline for that project, you can do the following:

```console
% git clone https://github.com/apple/swift-openapi-generator
% cd swift-openapi-generator/IntegrationTests
% swift package edit swift-openapi-runtime path/to/checkout/of/swift-openapi-runtime
% swift build
```

If you're working manually on this, you may wish to reset any overrides, you
can do this using the following command:

```console
% swift package reset
```
