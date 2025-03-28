import XCTest
import JSONSchema

class TestCustomValidator: XCTestCase {
    var schema: [String: Any]!
    
    override func setUp() {
        super.setUp()
        // Sample schema for various test cases, mirroring the Python tests
        schema = [
            "type": "object",
            "properties": [
                "Sodium": [
                    "type": "integer",
                    "description": "Sodium level in mg."
                ],
                "Carbohydrate": [
                    "type": "string",
                    "enum": ["Low", "High"]
                ],
                "FluidRestriction": [
                    "type": "integer",
                    "description": "Fluid restriction in cc/24 hours."
                ],
                "Diet": [
                    "type": "object",
                    "properties": [
                        "HighProtein": [
                            "type": "integer"
                        ],
                        "LowProtein": [
                            "type": "integer"
                        ],
                        "DietType": [
                            "type": "string",
                            "enum": ["Vegetarian", "Non-Vegetarian", "Vegan"]
                        ]
                    ],
                    "additionalProperties": false
                ]
            ] as [String: Any],
            "required": ["Sodium"],
            "additionalProperties": false
        ]
    }
    
    func testValidInstance() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": "Low",
            "FluidRestriction": 1500,
            "Diet": [
                "HighProtein": 100,
                "DietType": "Vegan"
            ] as [String: Any]
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance")
    }
    
    func testMissingRequiredProperty() throws {
        let instance: [String: Any] = [
            "Carbohydrate": "Low",
            "FluidRestriction": 1500
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertFalse(result.valid, "Expected invalid instance due to missing required property")
    }
    
    func testEnumWithNullableValid() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": NSNull()  // Enum property is null
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with null enum property")
    }
    
    func testEnumWithNullableInvalid() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": "Medium"  // Not in the enum
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertFalse(result.valid, "Expected invalid instance with invalid enum value")
    }
    
    func testEnumSubpropertyWithNullableValid() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Diet": [
                "DietType": NSNull()  // Enum subproperty is null
            ] as [String: Any]
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with null enum subproperty")
    }
    
    func testEnumSubpropertyWithNullableInvalid() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Diet": [
                "DietType": "Keto"  // Not in the enum for DietType
            ] as [String: Any]
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertFalse(result.valid, "Expected invalid instance with invalid enum subproperty")
    }
    
    func testIgnoreNoneForMissingProperties() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": NSNull()
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with null property")
    }
    
    func testRejectAdditionalProperties() throws {
        let instance: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": "Low",
            "ExtraField": "NotAllowed"  // Extra field not in the schema
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertFalse(result.valid, "Expected invalid instance with extra property")
    }
    
    func testAllowMissingNonRequiredFields() throws {
        let instance: [String: Any] = [
            "Sodium": 140  // Only the required field is present
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with only required field")
    }
    
    func testAllowNoneTypeHandling() throws {
        // Test with nil as the entire instance (should pass)
        let instance = NSNull()
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with NSNull")
    }
    
    func testNestedObjectWithAdditionalProperties() throws {
        // Nested schema with additionalProperties = false
        let nestedSchema: [String: Any] = [
            "type": "object",
            "properties": [
                "Diet": [
                    "type": "object",
                    "properties": [
                        "Sodium": ["type": "integer"],
                        "FluidRestriction": ["type": "integer"]
                    ],
                    "additionalProperties": false
                ]
            ]
        ]
        
        let validInstance: [String: Any] = [
            "Diet": [
                "Sodium": 140,
                "FluidRestriction": 1500
            ] as [String: Any]
        ]
        
        let invalidInstance: [String: Any] = [
            "Diet": [
                "Sodium": 140,
                "ExtraField": "NotAllowed"  // Additional field in nested object
            ] as [String: Any]
        ]
        
        let validResult = try customValidate(validInstance, schema: nestedSchema)
        XCTAssertTrue(validResult.valid, "Expected valid instance for nested object")
        
        let invalidResult = try customValidate(invalidInstance, schema: nestedSchema)
        XCTAssertFalse(invalidResult.valid, "Expected invalid instance with extra property in nested object")
    }
    
    func testNestedObjectNoneValid() throws {
        // Test with NSNull as a nested object
        let instance: [String: Any] = [
            "Sodium": 140,
            "Diet": NSNull()  // Should be valid since Diet is not required
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with null nested object")
    }
    
    func testNestedObjectMissingValid() throws {
        // Test with missing nested object
        let instance: [String: Any] = [
            "Sodium": 140  // Diet object is missing but should be valid
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with missing nested object")
    }
    
    func testExcludeAnyField() throws {
        // Test that any non-required field can be excluded without raising an error
        let instance: [String: Any] = [
            "Sodium": 140  // Only the required field is present
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with only required field")
    }
    
    func testEnumFieldNullableAndMissing() throws {
        // Test that a nullable enum field can be missing or null
        let instance: [String: Any] = [
            "Sodium": 140  // Carbohydrate is missing
        ]
        
        let result = try customValidate(instance, schema: schema)
        XCTAssertTrue(result.valid, "Expected valid instance with missing enum field")
        
        let instanceWithNone: [String: Any] = [
            "Sodium": 140,
            "Carbohydrate": NSNull()  // Carbohydrate is explicitly set to null
        ]
        
        let resultWithNone = try customValidate(instanceWithNone, schema: schema)
        XCTAssertTrue(resultWithNone.valid, "Expected valid instance with null enum field")
    }
} 