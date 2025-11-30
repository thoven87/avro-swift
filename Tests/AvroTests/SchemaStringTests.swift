import AvroFixtures
import Foundation
import Testing

@testable import Avro

@Suite("Schema String Tests")
struct SchemaStringTests {

	@AvroSchema
	struct TestRecord: Codable {
		let id: Int
		let name: String
	}

	@Test("avroSchemaString generates valid JSON for simple record")
	func testAvroSchemaStringSimpleRecord() throws {
		let schemaString = try TestRecord.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")
		#expect(json?["name"] as? String == "TestRecord")

		let fields = json?["fields"] as? [[String: Any]]
		#expect(fields?.count == 2)

		let fieldNames = fields?.compactMap { $0["name"] as? String }.sorted()
		#expect(fieldNames == ["id", "name"])
	}

	@Test("avroSchemaString matches FlatRecordFixture schema")
	func testAvroSchemaStringFlatRecord() throws {
		let schemaString = try FlatRecordFixture.Def.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")
		#expect(json?["name"] as? String == "Def")

		let fields = json?["fields"] as? [[String: Any]]
		#expect(fields?.count == 3)

		let fieldNames = fields?.compactMap { $0["name"] as? String }.sorted()
		#expect(fieldNames == ["email", "id", "name"])

		let idField = fields?.first { ($0["name"] as? String) == "id" }
		#expect(idField?["type"] as? String == "long")

		let nameField = fields?.first { ($0["name"] as? String) == "name" }
		#expect(nameField?["type"] as? String == "string")

		let emailField = fields?.first { ($0["name"] as? String) == "email" }
		#expect(emailField?["type"] as? String == "string")
	}

	@Test("avroSchemaString handles nested records")
	func testAvroSchemaStringNestedRecord() throws {
		let schemaString = try NestedRecordFixture.Def.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")
		#expect(json?["name"] as? String == "Def")

		let fields = json?["fields"] as? [[String: Any]]
		#expect(fields?.count == 4)

		let addressField = fields?.first { ($0["name"] as? String) == "address" }
		#expect(addressField != nil)

		let addressType = addressField?["type"] as? [String: Any]
		#expect(addressType?["type"] as? String == "record")
		#expect(addressType?["name"] as? String == "Def")
	}

	@Test("avroSchemaString handles arrays")
	func testAvroSchemaStringWithArray() throws {
		let schemaString = try ArrayFixture.Def.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")

		let fields = json?["fields"] as? [[String: Any]]
		let arrayField = fields?.first { ($0["name"] as? String) == "strings" }

		let arrayType = arrayField?["type"] as? [String: Any]
		#expect(arrayType?["type"] as? String == "array")
		#expect(arrayType?["items"] as? String == "string")
	}

	@Test("avroSchemaString handles maps")
	func testAvroSchemaStringWithMap() throws {
		let schemaString = try MapFixture.Def.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")

		let fields = json?["fields"] as? [[String: Any]]
		let mapField = fields?.first { ($0["name"] as? String) == "stringToInt" }

		let mapType = mapField?["type"] as? [String: Any]
		#expect(mapType?["type"] as? String == "map")
		#expect(mapType?["values"] as? String == "int")
	}

	@Test("avroSchemaString handles complex nested structures")
	func testAvroSchemaStringComplexFixture() throws {
		let schemaString = try ComplexFixture.Def.avroSchemaString

		let data = try #require(schemaString.data(using: .utf8))
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
		#expect(json != nil)

		#expect(json?["type"] as? String == "record")
		#expect(json?["name"] as? String == "Def")

		let fields = json?["fields"] as? [[String: Any]]
		#expect(fields != nil)
		#expect((fields?.count ?? 0) > 0)

		let fieldNames = fields?.compactMap { $0["name"] as? String }
		#expect(fieldNames?.contains("metadata") == true)
		#expect(fieldNames?.contains("tags") == true)
		#expect(fieldNames?.contains("nestedData") == true)
		#expect(fieldNames?.contains("arrayOfMaps") == true)
	}
}
