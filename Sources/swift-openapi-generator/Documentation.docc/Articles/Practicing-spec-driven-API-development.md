# Practicing spec-driven API development

Design, iterate on, and generate both client and server code from your hand-written OpenAPI document.

## Overview

An OpenAPI document represents a machine-readable _contract_ between a server and its clients.

There are two high-level workflows for creating and using the OpenAPI document:

- **Spec-driven development**:
    - OpenAPI document is hand-written.
    - Client and server code is generated.
- **Code-driven development**:
    - Server code is hand-written.
    - OpenAPI document and client code are generated.

This guide walks through these two practices and later describes how to migrate from a code-driven to a spec-driven development process to improve collaboration and consistency.

### (Recommended) Spec-driven development

Starting with an API contract and iterating on it allows developers working on both sides of the API to be involved in the API design process from the start.

Creating an OpenAPI document is no different, describing both the methods to call and the data structures of parameters and responses.

By starting with a draft of an OpenAPI document, both server and client teams can work in parallel as they write the code necessary to implement their portion of the API, gather feedback, and propose improvements for future versions.

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

An OpenAPI document supports client-side developers creating a mock server and starting work on the client to provide feedback in parallel to server-side development.

> Important: Spec-driven development allows server-side and client-side developers to collaborate on the API contract as equal peers and to work in parallel from the start.

Without starting with an OpenAPI document, client-side developers are frequently forced to wait to provide input about the interface. As a result, working from an API specification first allows for quicker iteration than a code-driven workflow, as there is less waiting of teams for one another.

Swift OpenAPI Generator generates both the client and server stub code, helping ensure that the implementation of both sides follows the agreed-upon OpenAPI document.

Collaborate on the API definition, as opposed to code, to less expensively iterate on the OpenAPI document.

Browse and edit OpenAPI documents using tools available in the broader OpenAPI community, with many that support syntax highlighting, autocompletion, and validation.

> Note: After a stable version of the API is released, take more care during iteration to avoid breaking changes until the next major version. For more information about the different levels of API stability, check out <doc:API-stability-of-generated-code>.

### (Discouraged) Code-driven development

Code-driven development, or in other words, writing server code first, and generating the OpenAPI document from it, is discouraged.

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

While initially it can appear convenient, communications with client teams can quickly become confused and ambiguous without a formal description of the API.

Additionally, as multiple teams provide feedback for an API service, there is no single point of truth for all the teams to reference, which slows down iteration.

In code-driven development, there isn't a convenient way for clients to propose API changes in an unambiguous, machine-readable way. They would have to get access to the source code of the server, understand how it's implemented, and make changes to it in a way that produces the desired change to the OpenAPI document. 

A code-driven workflow prioritizes server-side development over client-side development, in contrast to spec-driven development, where they work as equal peers throughout the API lifecycle.

Code-driven development also doesn't allow client teams to prototype their components until the server developers wrote at least enough code to generate the OpenAPI document, further limiting parallelization and delaying important learnings, making feedback more difficult to integrate.

> Warning: Code-driven development prioritizes server-side development over client-side development and introduces delays, especially during initial API development.

For these reasons, use or migrate to a spec-driven development workflow, as it allows all API stakeholders to work and iterate as equal peers.

To learn about migrating from your existing workflow to a spec-driven workflow incrementally, check out [this later section](#Migrate-from-code-driven-to-spec-driven-development).

### Use tests and sample apps as initial clients

When developing a service without having clients yet, use integration tests and sample apps as your first "clients".

Integration tests written against stubs generated by Swift OpenAPI Generator can simulate a separate team using the API, and can illustrate and feed back issues during the API design process.

In addition to integration tests, prototyping a sample client app helps drive end-to-end validation and puts the server-side developers in the shoes of their client-side counterparts, in the absence of real client teams.

### Publish the source of truth

In comparing the two possible workflows, as yourself the following questions:

1. What is the source of truth for the API? In other words, what is the representation that developers edit by hand?

2. What is the representation that the server provider publishes for clients, who consume it either through tooling or by directly reading it?

| Workflow | Source of truth | Published | Transcoding |
|----------|-----------------|-----------|-------------|
| Spec-driven | OpenAPI doc | OpenAPI doc | None required ✅ |
| Code-driven | Code | OpenAPI doc | Can be lossy and unpredictable ❌ |

Notice from the table above that the recommended spec-driven workflow publishes the same document that the developers of the server use to define the server's API (source of truth).

Publishing the source of truth is preferable to relying on transcoding from code (or other representations) to an OpenAPI document.

By inferring the specification from existing code, the resulting OpenAPI spec is often lossy and incomplete. And even with annotated code, it can be difficult to predict the OpenAPI output.

Additionally, any feature unsupported by the transcoder cannot be represented in the generated OpenAPI document, further limiting the creativity and expressiveness of the API.

> Tip: Publish the source of truth, not a representation transcoded from the source of truth.

This way, your clients can suggest changes to your OpenAPI document without having to learn how your server is implemented, or even having access to your source code.

### Migrate from code-driven to spec-driven development

> SeeAlso: Check out the [server development](https://developer.apple.com/wwdc23/10171?time=972) section of the WWDC session or the server tutorial (<doc:ServerSwiftPM>) before completing this section.

This section is a step-by-step guide that shows how to migrate an example service from code-driven to spec-driven development incrementally, one operation at a time.

Migrating incrementally helps reduce risk of large code changes and allows you to evaluate and improve the process before migrating your whole codebase.

#### Initial state

This example starts with a [Vapor](https://github.com/vapor/vapor) server that has 3 endpoints:

- `GET /foo`
- `POST /foo`
- `GET /bar`

The existing server might look something like this:

```swift
let app = Vapor.Application()
app.get("foo") { ... a, b, c ... }
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }
try await app.execute()
```

Each request handler is responsible for three things:
- a. Parse and validate inputs from a raw `Vapor.Request`.
- b. Perform any business logic specific to that handler.
- c. Serialize outputs into a raw `Vapor.Response`.

The application-specific business logic (b) is the core of the handler, while input (a) and output (c) transformation is often repetitive code that Swift OpenAPI Generator can generate for you.

#### Configure the generator plugin

To take advantage of the generator, create a new OpenAPI document with no paths in it, looking like this:

```yaml
openapi: 3.1.0
info:
  title: MyService
  version: 1.0.0
paths: {}
```

The example above is a valid OpenAPI document that describes a service with no endpoints.

Save the initial OpenAPI document to `Sources/MyServer/openapi.yaml` and then follow the tutorial of configuring the Swift OpenAPI Generator for a server project: <doc:ServerSwiftPM>.

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

try await app.execute()
```

At this point, you have two sets of endpoints, your existing 3 ones, and 0 generated ones (because your OpenAPI document is still empty).

Now you can commit and push the changes, and none of your existing code should be affected.

You've taken the first step towards spec-driven development.

#### Move over the first operation

Migrate the first route, `GET /foo`, and leave the other two alone for now.

Add the definition of the route to the OpenAPI document, so it looks something like this:

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

Comment out the first of the existing route implementations in your Vapor app:

```swift
let app = Vapor.Application()

// Registers your existing routes.
// app.get("foo") { ... a, b, c ... } // <<< just comment this out, and this route will be registered below by registerHandlers, as it is now defined by your OpenAPI document.
app.post("foo") { ... a, b, c ... }
app.get("bar") { ... a, b, c ... }

struct Handler: APIProtocol {} // <<< this is where you now get a build error

let transport = VaporTransport(routesBuilder: app)
try handler.registerHandlers(on: transport, serverURL: ...)

try await app.execute()
```

When you compile the example above, you'll get a build error because `APIProtocol` contains the requirement to implement the `getFoo` operation, but it isn't yet implemented.

Xcode will offer a Fix-it, and if you accept it, it will drop in a function stub that you can fill in:

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

try await app.execute()
```

Now, build and run!

Only one operation was moved over, but you can already test that it works and even deploy the service.

#### Repeat for the remaining operations

At this point, `POST /foo` and `GET /bar` are still manually implemented, but `GET /foo` is coming from the OpenAPI document and you only had to move the business logic over.

Repeat this for the remaining two operations, until there are no manual operations with business logic.

Endpoints that provide static content, such as CSS or JavaScript files, are not usually considered part of the REST API, so they don't need to be included in the OpenAPI document.

#### Final state

The end result should look something like this:

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

try await app.execute()
```

By migrating your service step-by-step, you can minimize risk and get increasing value from spec-driven development as you move operations into the hand-written OpenAPI document.
