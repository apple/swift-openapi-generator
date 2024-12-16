# Configuring the generator

Create a configuration file to control the behavior of the generator.

## Overview

Swift OpenAPI Generator build plugin requires a configuration file that controls what files are generated.

The command-line tool also uses the same configuration file.

### Create a configuration file

The configuration file is named `openapi-generator-config.yaml` or `openapi-generator-config.yml` and must exist in the target source directory.

> In the following tutorial, we will use `openapi-generator-config.yaml` as an example.

```text
.
├── Package.swift
└── Sources
    └── MyTarget
        ├── MyCode.swift
        ├── openapi-generator-config.yaml <-- place the file here
        └── openapi.yaml
```

The configuration file has the following keys:

- `generate` (required): array of strings. Each string value is a mode for the generator invocation, which is one of:
    - `types`: Common types and abstractions used by generated client and server code.
    - `client`: Client code that can be used with any client transport (depends on code from `types`).
    - `server`: Server code that can be used with any server transport (depends on code from `types`).
- `accessModifier` (optional): a string. Customizes the visibility of the API of the generated code.
    - `public`: Generated API is accessible from other modules and other packages (if included in a product).
    - `package`: Generated API is accessible from other modules within the same package or project.
    - `internal` (default): Generated API is accessible from the containing module only.
- `additionalImports` (optional): array of strings. Each string value is a Swift module name. An import statement will be added to the generated source files for each module.
- `filter` (optional): Filters to apply to the OpenAPI document before generation.
    - `operations`: Operations with these operation IDs will be included in the filter.
    - `tags`: Operations tagged with these tags will be included in the filter.
    - `paths`: Operations for these paths will be included in the filter.
    - `schemas`: These (additional) schemas will be included in the filter.
- `namingStrategy` (optional): a string. The strategy of converting OpenAPI identifiers into Swift identifiers.
    - `defensive` (default): Produces non-conflicting Swift identifiers for any OpenAPI identifiers. Check out [SOAR-0001](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0001) for details.
    - `idiomatic`: Produces more idiomatic Swift identifiers for OpenAPI identifiers. Might produce name conflicts (in that case, switch back to `defensive`). Check out [SOAR-0013](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0013) for details.
- `nameOverrides` (optional): a string to string dictionary. Allows customizing how individual OpenAPI identifiers get converted to Swift identifiers.
- `featureFlags` (optional): array of strings. Each string must be a valid feature flag to enable. For a list of currently supported feature flags, check out [FeatureFlags.swift](https://github.com/apple/swift-openapi-generator/blob/main/Sources/_OpenAPIGeneratorCore/FeatureFlags.swift).

### Example config files

To generate client code in a single target:

```yaml
generate:
  - types
  - client
namingStrategy: idiomatic
```

To generate server code in a single target:

```yaml
generate:
  - types
  - server
namingStrategy: idiomatic
```

If you are generating client _and_ server code, you can generate the types in a shared target using the following config:

```yaml
generate:
  - types
namingStrategy: idiomatic
```

Then, to generate client code that depends on the module from this target, use the following config (where `APITypes` is the name of the library target that contains the generated `types`):

```yaml
generate:
  - client
namingStrategy: idiomatic
additionalImports:
  - APITypes
```

To use the generated code from other packages, also customize the access modifier:

```yaml
generate:
  - client
namingStrategy: idiomatic
additionalImports:
  - APITypes
accessModifier: public
```

### Document filtering

The generator supports filtering the OpenAPI document prior to generation, which can be useful when
generating client code for a subset of a large API, or splitting an implementation of a server across multiple modules.

For example, to generate client code for only the operations with a given tag, use the following config:

```yaml
generate:
  - types
  - client
namingStrategy: idiomatic

filter:
  tags:
    - myTag
```

When multiple filters are specified, their union will be considered for inclusion.

In all cases, the transitive closure of dependencies from the components object will be included.

The CLI also provides a `filter` command that takes the same configuration file as the `generate`
command, which can be used to inspect the filtered document:

```console
% swift-openapi-generator filter --config path/to/openapi-generator-config.yaml path/to/openapi.yaml
```

To use this command as a standalone filtering tool, use the following config and redirect stdout to a new file:

```yaml
generate: []
filter:
  tags:
    - myTag
```
