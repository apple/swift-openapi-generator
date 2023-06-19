# Manually invoking the generator CLI

Manually invoke the command-line tool to generate code as an alternative to the Swift package plugin.

## Overview

The recommended workflow is to use the Swift package plugin, as described in our tutorials:

- <doc:ClientSwiftPM>
- <doc:ClientXcode>
- <doc:ServerSwiftPM>

When using the package plugin, the code is generated at build time and is not commited to your source repository.

If you need to commit the generated code to your source repository (for example, for auditing reasons) you can manually invoke the generator CLI to generate the Swift code.

> Note: The generated code still depends on the runtime library.

### Invoke the CLI manually

To generate Swift code to a specific directory, clone the generator repository and run the following command from the checkout directory:

```console
% swift run swift-openapi-generator generate \
    --mode types --mode client \
    --output-directory path/to/desired/output-dir \
    path/to/openapi.yaml
```

This will create the following files in the specified output directory:

- `Types.swift`
- `Client.swift`

> Warning: This command will overwrite existing files with the same name in the output directory.

To see the usage documentation for the generator CLI, use the following command:

```zsh
% swift run swift-openapi-generator --help
```
