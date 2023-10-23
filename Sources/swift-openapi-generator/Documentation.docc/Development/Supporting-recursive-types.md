# Supporting recursive types

Learn how the generator supports recursive types.

## Overview

In some applications, the most expressive way to represent arbitrarily nested data is using a type that holds another value of itself, either directly, or through another type. We refer to such types as _recursive types_.

By default, structs and enums do not support recursion in Swift, so the generator needs to detect recursion in the OpenAPI document and emit a different internal representation for the Swift types involved in recursion.

This article discusses the details of what boxing is, and how the generator chooses the types to box.

### Examples of recursive types

One example of a recursive type would be a file system item, representing a tree. The `FileItem` node contains more `FileItem` nodes in an array.

```yaml
FileItem:
  type: object
  properties:
    name:
      type: string
    isDirectory:
      type: boolean
    contents:
      type: array
      items:
        $ref: '#/components/schemas/FileItem'
  required:
    - name
```

Another example would be a `Person` type, that can have a `partner` property of type `Person`.

```yaml
Person:
  type: object
  properties:
    name:
      type: string
    partner:
      $ref: '#/components/schemas/Person'
  required:
    - name
```

### Recursive types in Swift

In Swift, the generator emits structs or enums for JSON schemas that support recursion (enums for `oneOf`, structs for `object`, `allOf`, and `anyOf`). Both structs and enums require that their size is known at compile time, however for arbitrarily nested values, such as a file system hierarchy, it cannot be known at compile time how deep the nesting goes. If such types were generated naively, they would not compile.

To allow recursion, a _reference_ Swift type must be involved in the reference cycle (as opposed to only _value_ types). We call this technique of using a reference type for storage inside a value type "boxing" and it allows for the outer type to keep its original API, including value semantics, but at the same time be used as a recursive type.

### Boxing different Swift types

- Enums can be boxed by adding the `indirect` keyword to the declaration, for example by changing:

```swift
public enum Directory {}
```

to:

```swift
public indirect enum Directory { ... }
```

When an enum type needs to be boxed, the generator simply includes the `indirect` keyword in the generated type.

- Structs require more work, including:
    - Moving the stored properties into a private `final class Storage` type.
    - Adding an explicit setter and getter for each property that calls into the storage.
    - Adjusting the initializer to forward the initial values to the storage.
    - Using a copy-on-write wrapper for the storage to avoid creating copies unless multiple references exist to the value and it's being modified.

For example, the original struct:
```swift
public struct Person {
    public var partner: Person?
    public init(partner: Person? = nil) {
        self.partner = partner
    }
}
```

Would look like this when boxed:
```swift
public struct Person {
    public var partner: Person? {
        get { storage.value.partner }
        _modify { yield &storage.value.partner }
    }
    public init(partner: Person? = nil) {
        self.storage = .init(Storage(partner: partner))
    }
    private var storage: CopyOnWriteBox<Storage>
    private final class Storage {
        var partner: Person?
        public init(partner: Person? = nil) {
            self.partner = partner
        }
    }
}
```

> Note: The above is an illustrative, simplified example. See the file-based reference tests for the exact shape of generated boxed types.

The details of the copy-on-write wrapper can be found in the runtime library, where it's defined.

- Arrays and dictionaries are reference types under the hood (but retain value semantics) and can already be considered boxed. For that reason, the first example that showed a `FileItem` type actually would compile successfully, because the `contents` array is already boxed. That means the `FileItem` type itself does not require boxing.

- Pure reference schemas can contribute to reference cycles, but cannot be boxed, because they are represented as a `typealias` in Swift. For that reason, the algorithm never chooses a `$ref` type for boxing, and instead boxes the next eligible type in the cycle.

### Computing which types need boxing

Since a boxed type requires an internal reference type, and can be less performant than a non-recursive value type, the generator implements an algorithm that _minimizes_ the number of boxed types required to make all the reference cycles still build successfully.

The algorithm outputs a list of type names that require boxing.

It iterates over the types defined in `#/components/schemas`, in the order defined in the OpenAPI document, and for each type walks all of its references.

Once it detects a reference cycle, it adds the first type in the cycle, in other words the one to which the last reference closed the cycle.

For example, walking the following:
```
A -> B -> C -> B
```

The algorithm would choose type "B" for boxing.
