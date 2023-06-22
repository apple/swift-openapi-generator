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
- `additionalImports` (optional): array of strings. Each string value Swift module name. An import statement will be added to the generated source files for each module.

### Example config files

To generate client code in a single target:

```yaml
generate:
  - types
  - client
```

To generate server code in a single target:

```yaml
generate:
  - types
  - server
```

If you are generating client _and_ server code, you can generate the types in a shared target using the following config:

```yaml
generate:
  - types
```

Then, to generate client code that depends on the module from this target, use the following config (where `APITypes` is the name of the library target that contains the generated `types`):

```yaml
generate:
  - client
additionalImports:
  - APITypes
```
