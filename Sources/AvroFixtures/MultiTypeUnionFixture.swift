//
//  MultiTypeUnionFixture.swift
//  avro-swift
//
//  Created by Felix Ruppert on 23.11.25.
//

import Avro
import Foundation

public enum MultiTypeUnionFixture {

	@AvroUnion
	public enum NumericValue: Codable, Equatable, Sendable {
		case int(Int32)
		case long(Int64)
		case double(Double)
	}

	@AvroSchema
	public struct Def: Codable, Equatable, Sendable {
		let id: Int32
		let value: NumericValue
	}

	public static let schema: AvroSchemaDefinition = .record(
		name: "NumericRecord",
		fields: [
			.init(name: "id", type: .int),
			.init(name: "value", type: .union([.int, .long, .double]))
		]
	)

	public static let avroSchemaString = """
		{
		  "type": "record",
		  "name": "NumericRecord",
		  "fields": [
		    {
		      "name": "id",
		      "type": "int"
		    },
		    {
		      "name": "value",
		      "type": ["int", "long", "double"]
		    }
		  ]
		}
		"""

	public static let instance = Def(id: 42, value: .double(3.14))

	public static let serialized = Data([
		0x54, 0x04, 0x1f, 0x85, 0xeb, 0x51, 0xb8, 0x1e, 0x09, 0x40
	])

}
