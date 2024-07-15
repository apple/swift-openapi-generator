# Common types between client and server modules

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example shows how you can structure a Swift package to share the types
from an OpenAPI document between a client and server module by having a common
target that runs the generator in `types` mode only.

This allows you to write extensions or other helper functions that use these
types and use them in both the client and server code.

## Usage

Build and run the server using:

```console
% swift run hello-world-server
Build complete!
...
info HummingBird : [HummingbirdCore] Server started and listening on 127.0.0.1:8080
```

Then, in another terminal window, run the client:

```console
% swift run hello-world-client
Build complete!
+––––––––––––––––––+
|+––––––––––––––––+|
||Hello, Stranger!||
|+––––––––––––––––+|
+––––––––––––––––––+
```

Note how the message is boxed twice: once by the server and once by the client,
both using an extension on a shared type, defined in the `Types` module.
