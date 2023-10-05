# Handling nullable schemas

Learn how the generator handles schema nullability.

## Overview

Both the OpenAPI specification itself and JSON Schema, which OpenAPI uses to describe payloads, make the important distinction between optional and required values.

As Swift not only supports, but enforces this distinction as well, Swift OpenAPI Generator represents nullable schemas as optional Swift values.

This document describes the rules used to decide which generated Swift types and properties are marked as optional. 

### Optionality in OpenAPI and JSON Schema

[OpenAPI 3.0.3](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.3.md) uses JSON Schema [Draft 5](https://json-schema.org/specification-links.html#draft-5), while [OpenAPI 3.1.0](https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.1.0.md) uses JSON Schema [2020-12](https://json-schema.org/specification-links.html#2020-12). There are a few differences that we call out below, but it's important to be aware of the fact that the generator needs to handle both.

The generator uses a simple rule: if any of the places that hint at optionality mark a field as optional, the value is generated as optional. It can be thought of as an `OR` operator.

### Standalone schemas

A schema in JSON Schema Draft 5 (used by OpenAPI 3.0.3) can be marked as optional using:
- the `nullable` field, a Boolean, if enabled, the field can be omitted and defaults to nil

For example:

```yaml
MyOptionalString:
  type: string
  nullable: true
```

A schema in JSON Schema 2020-12 (used by OpenAPI 3.1.0) can be marked as optional by:
- adding `null` as one of the types, if present, the field can be omitted and defaults to nil
- the `nullable` keyword was removed in this JSON Schema version

For example:

```yaml
MyOptionalString:
  type: [string, null]
```

> The rule can be summarized as: `schema is optional := schema is nullable`, where being `nullable` is represented slightly differently between the two JSON Schema versions.

The nullability of a schema is propagated through references. That means if a schema is a reference, the generator looks up the target schema of the reference to decide whether the value is treated as optional.

### Schemas as object properties

In addition to the schema itself being marked as nullable, we also have to consider the context in which the schema is used.

When used as an object property, we must also consider the `required` array. For example, in the following example (valid for both JSON Schema and OpenAPI versions mentioned above), we have a JSON object with a required property `name` of type string, and an optional property `age` of type integer.

```yaml
MyPerson:
  type: object
  properties:
    name:
      type: string
    age:
      type: integer
  required:
    - name
```

Notice that the `required` array only contains `name`, but not `age`. In objects, a property being omitted from the `required` array also signals to the generator that the property should be treated as an optional.

Marking the schema itself as nullable _as well_ doesn't make a difference, it will still be treated as a single-wrapped optional. Same if the property is included in the `required` array but marked as `nullable`, it will be an optional.

That means the following alternative definition results in the same generated Swift code as the above.

```yaml
MyPerson:
  type: object
  properties:
    name:
      type: string
    age:
      type: [integer, null]
  required:
    - name
    - age # even though required, the nullability of the schema "wins"
```

> The rule can be summarized as: `property is optional := schema is nullable OR property is not required`.

### Schemas in parameters

Another context in which a schema can appear, in addition to being standalone or an object property, is as a parameter. Examples of parameters are header fields, query items, path parameters. The following also applies to request bodies, even though they're not technically parameters.

OpenAPI defines a separate `required` field on parameters, of a Boolean value, which defaults to false (meaning parameters are optional by default).

```yaml
parameters:
  - name: limit
    in: query
    schema:
      type: integer
```

The example above defines an optional query item called "limit" of type integer.

Such a property would be generated as an optional `Int`.

To mark the property as required, and get a non-optional `Int` value generated in Swift, add `required: true`.

```yaml
parameters:
  - name: limit
    in: query
    required: true
    schema:
      type: integer
```

This adds a third way to mark a value as optional to the previous two. Again, if any of them marks the parameter as optional, the generated Swift value will be optional as well.

> The rule can be summarized as: `parameter is optional := schema is nullable OR parameter is not marked required`.
