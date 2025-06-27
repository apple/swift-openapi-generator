# Streaming ChatGPT Proxy

An example project using [Swift OpenAPI Generator](https://github.com/apple/swift-openapi-generator).

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

A tailored API server, backed by ChatGPT, and client CLI, with end-to-end
streaming.

This package is the reference sources for the talk, _Live coding a streaming ChatGPT proxy with Swift OpenAPI—from scratch!, presented at:

- [FOSDEM 2025][fosdem25-swift-openapi]
- [try! Swift 2025][tryswift25]

> Join us as we build a ChatGPT client, from scratch, using Swift OpenAPI Generator. We’ll take advantage of Swift OpenAPI’s pluggable HTTP transports to reuse the same generated client to make upstream calls from a Linux server, providing end-to-end streaming, backed by async sequences, without buffering upstream responses.
>
> In this session you’ll learn how to:
>
> * Generate a type-safe ChatGPT macOS client and use URLSession OpenAPI transport.
> * Stream LLM responses using Server Sent Events (SSE).
> * Bootstrap a Linux proxy server using the Vapor OpenAPI transport.
> * Use the same generated ChatGPT client within the proxy by switching to the AsyncHTTPClient transport.
> * Efficiently transform responses from SSE to JSON Lines, maintaining end-to-end streaming.

The example provides an API for a fictitious _ChantGPT_ service, which produces
creative chants to sing at sports games. 🙌 🏟️ 🙌

## Usage

The upstream calls to ChatGPT require an API token, which is configured using the `OPENAI_TOKEN` environment variable.
Rename `.env.example` to `.env` and replace the placeholder with your token.

Build and run the server using:

```console
% swift run ProxyServer
2025-01-30T09:12:23+0000 notice codes.vapor.application : [Vapor] Server starting on http://127.0.0.1:8080
...
```

Then, from another terminal, run the proxy client using:

```console
% swift run ClientCLI "That team with the Bull logo"
Build of product 'ClientCLI' complete! (7.24s)
🧑‍💼: That one with the bull logo
---
🤖: **"Charge Ahead, Chicago Bulls!"**

(Verse 1)
Red and black, we’re on the prowl,
Chicago Bulls, hear us growl!
From the Windy City, we take the lead,
Charging forward with lightning speed!

(Chorus)
B-U-L-L-S, Bulls! Bulls! Bulls!
We’re the team that never dulls!
Hoops and hustle, heart and soul,
Chicago Bulls, we’re on a roll!
...
```

## Linux development with VS Code Dev Containers

The package also contains configuration for developing with VS Code [Dev
Containers][dev-containers].

If you have the Dev Containers extension installed, use the `Dev Containers: Reopen in Container` command to switch to build and run for Linux.

[fosdem25-swift-openapi]: https://fosdem.org/2025/schedule/event/fosdem-2025-5230-live-coding-a-streaming-chatgpt-proxy-with-swift-openapi-from-scratch-/
[tryswift25]: https://tryswift.jp/en/
[dev-containers]: https://code.visualstudio.com/docs/devcontainers/containers
