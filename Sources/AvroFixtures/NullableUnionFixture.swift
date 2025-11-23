//
//  NullableUnionFixture.swift
//  avro-swift
//
//  Created by Felix Ruppert on 23.11.25.
//

import Avro
import Foundation

public enum NullableUnionFixture {

	@AvroSchema
	public struct Def: Codable, Equatable, Sendable {
		let id: Int32
		let optionalName: String?
		let optionalEmail: String?
	}

	public static let schema: AvroSchemaDefinition = .record(
		name: "NullableUser",
		fields: [
			.init(name: "id", type: .int),
			.init(name: "optionalName", type: .union([.null, .string])),
			.init(name: "optionalEmail", type: .union([.null, .string]))
		]
	)

	public static let avroSchemaString = """
		{
		  "type": "record",
		  "name": "NullableUser",
		  "fields": [
		    {
		      "name": "id",
		      "type": "int"
		    },
		    {
		      "name": "optionalName",
		      "type": ["null", "string"]
		    },
		    {
		      "name": "optionalEmail",
		      "type": ["null", "string"]
		    }
		  ]
		}
		"""

	public static let instance = Def(id: 1, optionalName: "John Doe", optionalEmail: nil)

	public static let serialized = Data([
		0x02, 0x02, 0x10, 0x4a, 0x6f, 0x68, 0x6e, 0x20, 0x44, 0x6f, 0x65, 0x00
	])

}
