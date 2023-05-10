# API stability of the generator

Understand the impact of updating the generator package plugin on the generated Swift code.

## Overview

Swift OpenAPI Generator generates client and server Swift code from an OpenAPI document. The generated code may change if the OpenAPI document is changed or a different version of the generator is used.

This document outlines the API stability goals for the generated code to help you avoid unintentional build errors when updating to a new version of Swift OpenAPI Generator.

### API stability for versions >= 1.0.0

After the project reaches 1.0.0, we will follow [Semantic Versioning 2.0.0][0].

### API stability for versions 0.y.z

Swift OpenAPI Generator is being developed as an open source project. In order to accommodate feedback from the community, it does not yet have a 1.0.0 release. Until it does, we reserve the right to change the API between _minor_ versions (for example, between `0.2.0` and `0.3.0`), as described in the Semantic Version Specification[[1]][[2]].

> Tip: To avoid unexpected build issues, use `.upToNextMinor(from: "0.y.z")` in your `Package.swift` when declaring a dependency on Swift OpenAPI Generator packages (including the runtime and transport libraries).

## See Also

- <doc:API-stability-of-generated-code>

[0]: https://semver.org
[1]: https://semver.org/#spec-item-4
[2]: https://semver.org/#how-should-i-deal-with-revisions-in-the-0yz-initial-development-phase
