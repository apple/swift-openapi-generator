# API stability of generated code

Understand the impact of changes to the OpenAPI document on generated Swift code.

## Overview

Swift OpenAPI Generator generates client and server Swift code from an OpenAPI document. The generated code may change if the OpenAPI document is changed or a different version of the generator is used.

This document outlines the API stability goals for the generated code to help you avoid unintentional build errors when updating the OpenAPI document.

### Example changes

There are three API boundaries to consider:
- **HTTP**: the requests and responses sent over the network
- **OpenAPI**: the description of the API using the OpenAPI specification
- **Swift**: the client or server code generated from the OpenAPI document

Below is a table of example changes you might make to an OpenAPI document, and whether that would result in a breaking change (❌) or a non-breaking change (✅).

| Change | HTTP | OpenAPI | Swift |
| -: | :-: | :-: | :-: |
| Add a new schema | ✅ | ✅ | ✅ |
| Add a new property to an existing schema (†) | ✅ | ✅ | ⚠️ |
| Add a new operation | ✅ | ✅ | ✅ |
| Add a new response to an existing operation (‡) | ✅ | ❌ | ❌  |
| Add a new content type to an existing response (§) | ✅ | ❌ | ❌ |
| Remove a required property | ❌ | ❌ | ❌ |
| Rename a schema | ✅ | ❌ | ❌ |

> †: Safe change to make as long as no adopter captured the Swift function signature of the initializer of the generated struct, which gains a new parameter. Rare, but something to be aware of.

> ‡: Adding a new response to an existing operation introduces a new enum case that the adopter needs to handle, so is a breaking change in OpenAPI and Swift.

> §: Adding a new content type to an existing response is similar to ‡: it introduces a new enum case that the adopter needs to handle, so is a breaking change in OpenAPI and Swift.

The table above is not exhaustive, but it shows a pattern:
- Removing (or renaming) anything that the adopter might have relied on is usually a breaking change.
- Adding a new schema or a new operation is an additive, non-breaking change (†).
- Adding a new response or content type is considered a breaking change (‡)(§). 

### Avoid including the generated code in your public API

Due to the complicated rules above, we recommend that you don't publish the generated code for others to rely on.

If you do expose the generated code as part of your package's API, we recommend auditing your API for breaking changes, especially if your package uses Semantic Versioning.

Maintaining Swift library package that uses the generated code as an implementation detail is supported (and recommended), as long as no generated symbols are exported in your public API.

#### Create a curated client library package

Let's consider an example where you're creating a Swift library that provides a curated API for making the following API call:

```console
% curl http://example.com/api/hello/Maria?greeting=Howdy
{
  "message": "Howdy, Maria!"
}
```

You can hide the generated client code as an implementation detail and provide a hand-written Swift API to your users using the following steps:

1. Create a library target that is not exposed as a product, called, for example, `GeneratedGreetingClient`, which uses the Swift OpenAPI Generator package plugin.
2. Create another library target that is exposed as a product, called, for example, `Greeter`, which depends on the `GeneratedGreetingClient` target but doesn't use the imported types in its public API.

This way, you are in full control of the public API of the `Greeter` library, but you also benefit from calling the service using generated code.

## See Also

- <doc:API-stability-of-the-generator>
