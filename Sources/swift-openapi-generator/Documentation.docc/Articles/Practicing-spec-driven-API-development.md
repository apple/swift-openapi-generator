# Practicing spec-driven API development

Design, iterate on, and generate both client and server code from your hand-written OpenAPI document.

## Overview

An OpenAPI document represents a machine-readable _contract_ between a server and its clients.

There are two high-level workflows of creating and using the OpenAPI document:

- **Spec-driven development**:
    - OpenAPI document is hand-written.
    - Client and server code is generated.
- **Code-driven development**:
    - Server code is hand-written.
    - OpenAPI document and client code are generated.

This guide explains why spec-driven development is the recommended practice for use with Swift OpenAPI Generator.

### (Recommended) Spec-driven development

Starting with an API contract, before any server or client code is written, allows both the server and client teams to be involved in the API design process from the start.

The goal is to draft the initial OpenAPI document, then let both server and client teams work in parallel as they write the code necessary to implement their side, gather feedback, and propose the next version. This cycle never ends, however after a stable version is released, more care needs to be taken to avoid breaking changes until the next major version (learn more about API stability in <doc:API-stability-of-generated-code>.)

Having the OpenAPI document written before the server team writes any code allows the client team to spin up a mock server that follows the proposed API, and start work on the client.

Unblocking client teams allows for quicker iteration than a code-driven workflow, as there is less waiting of teams for one another.

```
                                   ┌────────────────────────────┐
                             ┌────▶│    Server Implementation   │
                             │     └────────────────────────────┘
                             │     ┌────────────────────────────┐
  ┌────────────────────┐     ├────▶│         App Client         │
  │  OpenAPI Document  │─────┤     └────────────────────────────┘
  └────────────────────┘     │     ┌────────────────────────────┐
                             ├────▶│         Web Client         │
                             │     └────────────────────────────┘
                             │     ┌────────────────────────────┐
                             └────▶│            ...             │
                                   └────────────────────────────┘
```

Swift OpenAPI Generator generates both the client and server stub code, helping ensure that the implementation of both sides follow the agreed-upon OpenAPI document. 

Collaborating on the API definition, as opposed to code, allows inexpensive iteration on the OpenAPI document. It is "just" a YAML or JSON file, after all, made easy to browse and edit using tools available in the broader OpenAPI community, offering syntax highlighting, autocompletion, and validation in many popular text editors.

### (Discouraged) Code-driven development

Code-driven development, or in other words, writing server code first, and generating the OpenAPI document from it, is discouraged for use with Swift OpenAPI Generator. 

While initially it can appear convenient, as server developers start writing code without having an agreed API contract first, it quickly slows down the iteration cycle as soon as clients get involed and start proposing changes.

```
                                                                  ┌────────────────────────────┐
                                                              ┌──▶│         App Client         │
                                                              │   └────────────────────────────┘
┌────────────────────────────┐       ┌────────────────────┐   │   ┌────────────────────────────┐
│    Server Implementation   │──────▶│  OpenAPI Document  │───┼──▶│         Web Client         │
└────────────────────────────┘       └────────────────────┘   │   └────────────────────────────┘
                                                              │   ┌────────────────────────────┐
                                                              └──▶│            ...             │
                                                                  └────────────────────────────┘
```

In code-driven development, there isn't a convenient way for clients to propose API changes in an unambiguous, machine-readable way. They would have to get access to the source code of the server, understand how it's implemented, and make changes to it in a way that produces the desired change to the OpenAPI document.

A code-driven workflow prioritizes server developers at the cost of their clients, in contrast to spec-driven development, where the server and client developers work as equal peers throughout the API lifecycle.

Code-driven development also doesn't allow client teams to prototype their components until the server developers wrote at least enough code to generate the OpenAPI document, further limiting parallelization and delaying important learnings, making feedback more difficult to integrate as more code has already been written by then.

For this reason, code-driven development is discouraged for use with Swift OpenAPI Generator, and should be replaced by spec-driven development, which allows all API stakeholders to work as peers from the beginning. To learn about migrating to spec-driven incrementally, check out [this later section](#Migrate-from-code-driven-to-spec-driven-development).

> Tip: When developing a service without having known clients yet, use integration tests and sample apps as your first "clients". The integration tests should not use any code from the server implementation, and can thus simulate a separate team trying to use the provided service API. Writing the integration tests can inform the server team of usability issues early and feed back into the API design process. In addition to integration tests, prototyping a sample client app can also help simulate the experience of client teams in the absence of real-world API clients.

### Publish the source of truth

Compare the workflows based on the following two properties:
1. What is the source of truth for the API? In other words, what is the representation that developers edit by hand?
2. What is the representation that the server provider publishes for the client, who consume it either through tooling or by directly reading it?

| Workflow | Source of truth | Published | Transcoding |
|----------|-----------------|-----------|-------------|
| Spec-driven | OpenAPI doc | OpenAPI doc | None required ✅ |
| Code-driven | Code | OpenAPI doc | Can be lossy and unpredictable ❌ |

Notice from the table above that the recommended spec-driven workflow publishes the same document that the developers of the server use to define the server's API (source of truth).

Publishing the source of truth is preferable to relying on transcoding from code (or other representations) to an OpenAPI document, which is often lossy and difficult to predict how a given language-specific annotation affects the OpenAPI output. It also means that any feature unsupported by the transcoder cannot be represented in the generated OpenAPI document.

> Tip: Publish the source of truth, not a representation transcoded from the source of truth. That way, your clients can open pull requests to your OpenAPI document without having to learn how your server is implemented, nor do they need access to the source code of your server.

### Migrate from code-driven to spec-driven development

> SeeAlso: Check out the [server development](https://developer.apple.com/wwdc23/10171?time=972) section of the WWDC session or the server tutorial (<doc:ServerSwiftPM>) before reading this section.

This section is a step-by-step guide of migrating an example service from code-driven to spec-driven development incrementally, one operation at a time. Migrating incrementally helps reduce risk of large code changes and allows you to evaluate and improve the workflow before migrating your whole codebase.

#### Initial state

Let's assume you're starting with a hand-written [Vapor](https://github.com/vapor/vapor) server that has 3 endpoints:
- `GET /foo`
- `POST /foo`
- `GET /bar`

So your existing server might look something like:

```swift
let app = Vapor.Application()
app.get("foo") { ... a, b, c ... }
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }
try app.run()
```

In each request handler, you have to do 3 things: 
- a. Parse and validate inputs from a raw `Vapor.Request`.
- b. Perform your handler-specific logic.
- c. Serialize outputs into a raw `Vapor.Response`.

The application-specific logic is (b), while (a) and (c) can be repetitive code, which Swift OpenAPI Generator can generate for you.

#### Configure the generator plugin

To take advantage of the generator, first create a new OpenAPI document with no paths in it, looking like this:

```yaml
openapi: 3.1.0
info:
  title: MyService
  version: 1.0.0
paths: {}
```

This is a valid OpenAPI document, one that describes a server with no endpoints.

Save it to `Sources/MyServer/openapi.yaml` and then follow the tutorial of configuring the Swift OpenAPI Generator for a server project: <doc:ServerSwiftPM>.

As you go through the tutorial, the important part is that you only _add_ the generated handlers _to your existing Vapor app_ instead of creating a new Vapor app. 

After this step, your code looks something like this:

```swift
let app = Vapor.Application()

// Registers your existing routes.
app.get("foo") { ... a, b, c ... }
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }

struct Handler: APIProtocol {} // this is where you'll implement your logic in the next step

let transport = VaporTransport(routesBuilder: app)
// Registers your generated routes from the OpenAPI document. Right now, there are 0.
try handler.registerHandlers(on: transport, serverURL: ...)

try app.run()
```

At this point, you have two sets of endpoints, your existing 3 ones, and 0 generated once (because your OpenAPI document is still empty). Now you can commit and push the changes, and none of your existing code should be affected. But you've already taken the first spec towards spec-driven development.

#### Move over the first operation

Let's migrate the first route, `GET /foo`, and leave the other two alone for now.

First, you add the definition for the route to the OpenAPI document, so it looks something like:

```yaml
openapi: 3.1.0
info:
  title: MyService
  version: 1.0.0
paths:
  /foo:
    get:
      ... (the definition of the operation, its inputs and outputs)
```

and comment out the first of the existing route implementations in your Vapor app:

```swift
let app = Vapor.Application()

// Registers your existing routes.
// app.get("foo") { ... a, b, c ... } // <<< just comment this out, and this route will be registered below by registerHandlers, as it is now defined by your OpenAPI document.
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }

struct Handler: APIProtocol {} // <<< this is where you now get a build error

let transport = VaporTransport(routesBuilder: app)
try handler.registerHandlers(on: transport, serverURL: ...)

try app.run()
```

If you try to compile the above, you'll get a build error. Because now, the `APIProtocol` contains the requirement to implement the `getFoo` operation, but you're not implementing it, yet. Xcode will offer a Fix-it, and drop in a function stub that you just fill in:

```swift
let app = Vapor.Application()

// Registers your existing routes.
// <<< now you can just delete the first original route, as you've moved the business logic below into the Handler type
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }

struct Handler: APIProtocol {
  func getFoo(input: Operations.getFoo.Input) async throws -> Operations.getFoo.Output {
    ... b ... // <<< notice that here you just implement your business logic, but input deserialization and validation, and output serialization is handled by the generated code.
  }
}
let transport = VaporTransport(routesBuilder: app)
try handler.registerHandlers(on: transport, serverURL: ...)

try app.run()
```

Now, build run, and test!

Only one operation was moved over, but you can get confidence that it works and even deploy the service.

#### Repeat for the remaining operations

At this point, `POST /foo` and `GET /bar` are still manually implemented, but `GET /foo` is coming from your OpenAPI document and you only had to move the business logic over.

At your convenience, repeat this for the remaining two operations, until you have no manual operations (or feel free to keep some manual operations there, for example for serving static css/js files, those endpoints usually don't go into the OpenAPI document, which is meant mainly for the REST API).

#### Final state

You should end up with something like this:

```swift
let app = Vapor.Application()

// Register some manual routes, for example, for serving static files.
app.middlewares.on(FileMiddleware(...))

// The business logic.
struct Handler: APIProtocol {
  func getFoo(input: Operations.getFoo.Input) async throws -> Operations.getFoo.Output {
    // ...
  }
  func postFoo(input: Operations.postFoo.Input) async throws -> Operations.postFoo.Output {
    // ...
  }
  func getBar(input: Operations.getBar.Input) async throws -> Operations.getBar.Output {
    // ...
  }
}

// Register the generated routes from OpenAPI.
let transport = VaporTransport(routesBuilder: app)
try handler.registerHandlers(on: transport, serverURL: ...)

try app.run()
```

By migrating your service step-by-step, you can minimize risk and get increasing value from spec-driven development as you move operations into the hand-written OpenAPI document.
