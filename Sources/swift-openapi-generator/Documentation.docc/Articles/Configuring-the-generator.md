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
- `additionalFileComments` (optional): array of strings. Each string value is a comment that will be added to the top of each generated file (after the do-not-edit comment). Useful for adding directives like `swift-format-ignore-file` or `swiftlint:disable all`.
- `filter` (optional): Filters to apply to the OpenAPI document before generation.
    - `operations`: Operations with these operation IDs will be included in the filter.
    - `tags`: Operations tagged with these tags will be included in the filter.
    - `paths`: Operations for these paths will be included in the filter.
    - `schemas`: These (additional) schemas will be included in the filter.
- `namingStrategy` (optional): a string. The strategy of converting OpenAPI identifiers into Swift identifiers.
    - `defensive` (default): Produces non-conflicting Swift identifiers for any OpenAPI identifiers. Check out [SOAR-0001](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0001) for details.
    - `idiomatic`: Produces more idiomatic Swift identifiers for OpenAPI identifiers. Might produce name conflicts (in that case, switch back to `defensive`). Check out [SOAR-0013](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0013) for details.
- `nameOverrides` (optional): a string to string dictionary. Allows customizing how individual OpenAPI identifiers get converted to Swift identifiers.
- `typeOverrides` (optional): Allows replacing a generated type with a custom type.
    - `schemas` (optional): a string to string dictionary. The key is the name of the schema, the last component of `#/components/schemas/Foo` (here, `Foo`). The value is the custom type name, such as `CustomFoo`. Check out details in [SOAR-0014](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0014).
- `featureFlags` (optional): array of strings. Each string must be a valid feature flag to enable. For a list of currently supported feature flags, check out [FeatureFlags.swift](https://github.com/apple/swift-openapi-generator/blob/main/Sources/_OpenAPIGeneratorCore/FeatureFlags.swift).
- `output` (optional): Controls the generated source-file layout.
    - `maxDeclarationsPerFile` (optional): A positive integer that limits the number of declarations in each split types namespace file.
    - `dependencyLayerCount` (optional): A positive integer that limits the number of dependency-ordered layers in the generated types files.

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

To add file comments to exclude generated files from formatting tools:

```yaml
generate:
  - types
  - client
namingStrategy: idiomatic
additionalFileComments:
  - "swift-format-ignore-file"
  - "swiftlint:disable all"
```

Types generation emits a fixed set of files organized by generated namespace:

- `Types.swift`
- `Types+Components.swift`
- `Types+Operations.swift`
- `Types+Components+Schemas.swift`
- `Types+Components+Parameters.swift`
- `Types+Components+RequestBodies.swift`
- `Types+Components+Responses.swift`
- `Types+Components+Headers.swift`

> Important: The number and names of generated files are _not_ considered to be stable, and can change at any time. For details, check out <doc:API-stability-of-the-generator>.

Each parent file owns its child namespace declarations, and the corresponding `+Namespace` files extend those
namespaces with generated declarations.

The file layout does not change generated Swift symbol names. For example, schema types remain nested under
`Components.Schemas`. When invoking the generator directly or checking generated sources into a repository, retain all
of the emitted files.

The command-line tool and command plugin can further split the declaration-bearing namespace files by setting a
maximum number of declarations per file:

```yaml
generate:
  - types
output:
  maxDeclarationsPerFile: 100
```

For example, a `Schemas` namespace with 250 declarations keeps its first 100 declarations in
`Types+Components+Schemas.swift`, then places the remaining declarations in two extension files:

- `Types+Components+Schemas+1.swift`
- `Types+Components+Schemas+2.swift`

The command-line tool and command plugin can also group generated types into dependency-ordered layers:

```yaml
generate:
  - types
output:
  dependencyLayerCount: 4
  maxDeclarationsPerFile: 100
```

Schemas that mutually reference each other remain in one strongly connected group. The generator puts schemas with
no dependencies in layer 0, then puts dependents in later layers so a generated declaration only references schemas
in its own or an earlier layer. Reusable parameters, headers, request bodies, and responses retain their existing
`Components` namespace and are assigned to the highest schema layer they reference. Operations are assigned using the
same rule.

The configured value is a maximum. If the schema graph is shallower, the generator does not emit empty layers. If the
graph is deeper, contiguous natural graph depths are folded proportionally into the requested count without changing
dependency order. Layered files use names such as `Types+Components+Schemas+Layer0.swift` and
`Types+Operations+Layer2.swift`.

When both output options are present, dependency grouping happens first and `maxDeclarationsPerFile` is applied to
each namespace layer independently. Schema-owned declaration groups and mutually recursive groups are not split, so
a single indivisible group can exceed the configured declaration maximum. Additional chunks append the existing
numeric suffix, for example `Types+Components+Schemas+Layer2+1.swift`.

The build-tool plugin does not support either dynamic output option because the number of generated files depends on
the input document, while build commands must declare their outputs before running the generator. Supporting these
options there requires migrating the plugin to a prebuild command.

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

### Type overrides

Type Overrides can be used used to replace the default generated type with a custom type.

```yaml
typeOverrides:
  schemas:
    UUID: Foundation.UUID
```

Check out [SOAR-0014](https://swiftpackageindex.com/apple/swift-openapi-generator/documentation/swift-openapi-generator/soar-0014) for details.
