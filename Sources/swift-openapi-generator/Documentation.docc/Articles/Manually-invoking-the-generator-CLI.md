# Manually invoking the generator CLI

Manually invoke the command-line tool to generate code as an alternative to the Swift package build plugin.

## Overview

The recommended workflow is to use the Swift package plugin, as described in our tutorials:

- <doc:ClientSwiftPM>
- <doc:ClientXcode>
- <doc:ServerSwiftPM>

When using the package plugin, the code is generated at build time and is not committed to your source repository.

If you need to commit the generated code to your source repository (for example, for auditing reasons) you can manually invoke the generator CLI to generate the Swift code. Note that even with this workflow, the generated code still depends on the runtime library.

> Tip: Check out <doc:Checking-out-an-example-project#Ahead-of-time-manual-code-generation> for example projects.

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

```console
% swift run swift-openapi-generator --help
```

> Note: By default, the code is generated with the `package` access modifier, to make the generated code visible from other packages, add `--access-modifier public` to the invocation.

### Use the Swift package command

As an alternative to invoking the CLI manually, you can also use the package command, which works similarly to the build plugin.

Set up the `openapi.yaml` and `openapi-generator-config.yaml` files the same way as you would for the build plugin, and then run:

```console
% swift package plugin generate-code-from-openapi --target HelloWorldURLSessionClient
```

This will generate files into the `HelloWorldURLSessionClient` target's Sources directory, in a directory called `GeneratedSources`, which you can then check into your repository.

You can also invoke the command from the Xcode UI by control-clicking on a target in the Project Navigator, and selecting the command.
