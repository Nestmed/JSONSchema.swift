import Foundation

public class CustomValidator: Draft7Validator {
  // Custom validations that override the default Draft7Validator behavior
  static let customValidations: [String: Validation] = [
    "properties": customProperties,
    "type": customType,
    "enum": customEnum,
    "additionalProperties": customAdditionalProperties
  ]
  
  public required init(schema: Bool) {
    super.init(schema: schema)
    
    // Override the validations in the base class
    for (key, validation) in CustomValidator.customValidations {
      validations[key] = validation
    }
  }
  
  public required init(schema: [String: Any]) {
    super.init(schema: schema)
    
    // Override the validations in the base class
    for (key, validation) in CustomValidator.customValidations {
      validations[key] = validation
    }
  }
  
  // Utility function to validate instance against schema
  public static func validate(instance: Any, schema: [String: Any]) throws -> ValidationResult {
    let validator = CustomValidator(schema: schema)
    return try validator.validate(instance: instance)
  }
}

// Custom properties validator that skips validation if the property is null or missing
func customProperties(context: Context, properties: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  // Skip validation if instance is None
  if instance is NSNull {
    return AnySequence(EmptyCollection())
  }
  
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }
  
  guard let properties = properties as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }
  
  return try AnySequence(instance.compactMap { (key, value) throws -> AnySequence<ValidationError>? in
    // If the property is missing in the instance or is null, skip validation for it
    if value is NSNull {
      return AnySequence(EmptyCollection())
    }
    
    if let schema = properties[key] {
      context.instanceLocation.push(key)
      defer { context.instanceLocation.pop() }
      return try context.descend(instance: value, subschema: schema)
    }
    
    return AnySequence(EmptyCollection())
  }.joined())
}

// Custom type validator that allows nil for any type
func customType(context: Context, typeValue: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  // Allow None for any type
  if instance is NSNull {
    return AnySequence(EmptyCollection())
  }
  
  // Use the standard type validator otherwise
  return type(context: context, type: typeValue, instance: instance, schema: schema)
}

// Custom enum validator that allows null for any enum property
func customEnum(context: Context, enumValue: Any, instance: Any, schema: [String: Any]) -> AnySequence<ValidationError> {
  // Allow None for any enum property
  if instance is NSNull {
    return AnySequence(EmptyCollection())
  }
  
  // Use the standard enum validator otherwise
  return `enum`(context: context, enum: enumValue, instance: instance, schema: schema)
}

// Custom additionalProperties validator that skips validation if instance is null
func customAdditionalProperties(context: Context, additionalProperties: Any, instance: Any, schema: [String: Any]) throws -> AnySequence<ValidationError> {
  // Skip validation if instance is null
  if instance is NSNull {
    return AnySequence(EmptyCollection())
  }
  
  guard let instance = instance as? [String: Any] else {
    return AnySequence(EmptyCollection())
  }
  
  let extras = findAdditionalProperties(instance: instance, schema: schema)
  
  if let additionalProperties = additionalProperties as? [String: Any] {
    return try AnySequence(extras.map {
      try context.descend(instance: instance[$0]!, subschema: additionalProperties)
    }.joined())
  }
  
  if let additionalProperties = additionalProperties as? Bool, !additionalProperties && !extras.isEmpty {
    let invalidProperties = Array(extras).sorted().joined(separator: ", ")
    return AnySequence([
      ValidationError(
        "Additional property '\(invalidProperties)' is not allowed.",
        instanceLocation: context.instanceLocation,
        keywordLocation: context.keywordLocation
      )
    ])
  }
  
  return AnySequence(EmptyCollection())
} 