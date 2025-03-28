# JSON Schema

An implementation of [JSON Schema](http://json-schema.org/) in Swift.
Supporting JSON Schema Draft 4, 6, 7, 2019-09, 2020-12.

The JSON Schema 2019-09 and 2020-12 support are incomplete and have gaps with
some of the newer keywords.

JSONSchema.swift does not support remote referencing [#9](https://github.com/kylef/JSONSchema.swift/issues/9).

## Installation

JSONSchema can be installed via [CocoaPods](http://cocoapods.org/).

```ruby
pod 'JSONSchema'
```

## Usage

```swift
import JSONSchema

try JSONSchema.validate(["name": "Eggs", "price": 34.99], schema: [
  "type": "object",
  "properties": [
    "name": ["type": "string"],
    "price": ["type": "number"],
  ],
  "required": ["name"],
])
```

### Error handling

Validate returns an enumeration `ValidationResult` which contains all
validation errors.

```python
print(try validate(["price": 34.99], schema: ["required": ["name"]]).errors)
>>> "Required property 'name' is missing."
```

### Custom Validator

This package also provides a CustomValidator that extends the standard JSON Schema validation with the following behaviors:

1. Allows `null` values for any type validation.
2. Allows `null` values for enum validations.
3. Skips validation for properties that are `null`.
4. Properly handles `null` values for nested objects.

To use the custom validator:

```swift
import JSONSchema

// Use the customValidate function
try JSONSchema.customValidate(["name": "Eggs", "price": NSNull()], schema: [
  "type": "object",
  "properties": [
    "name": ["type": "string"],
    "price": ["type": "number"],
  ],
  "required": ["name"],
])

// Or create a CustomValidator instance directly
let validator = CustomValidator(schema: mySchema)
try validator.validate(instance: myData)
```

This is particularly useful when validating data that may contain null values that should pass validation, even when the schema doesn't explicitly allow for nulls.

## License

JSONSchema is licensed under the BSD license. See [LICENSE](LICENSE) for more
info.

