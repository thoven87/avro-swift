//
//  EnumFixture.swift
//  avro-swift
//
//  Created by Felix Ruppert on 22.11.25.
//

import Avro
import Foundation

public enum EnumFixture {
	@AvroEnum(namespace: "com.example")
	public enum Department: String, Codable, Sendable {
		case ENGINEERING
		case SALES
		case MARKETING
		case HR
		case FINANCE
	}

	@AvroEnum(namespace: "com.example")
	public enum EmployeeStatus: String, Codable, Sendable {
		case ACTIVE
		case ON_LEAVE
		case TERMINATED
	}

	@AvroSchema
	public struct Def: Codable, Equatable, Sendable {
		let id: Int
		let name: String
		let department: Department
		let status: EmployeeStatus
	}

	public static let schema: AvroSchema = .record(
		name: "Employee",
		namespace: "com.example",
		fields: [
			.init(name: "id", type: .int),
			.init(name: "name", type: .string),
			.init(name: "department", type: Department.avroSchema),
			.init(
				name: "status",
				type: .enum(
					name: "EmployeeStatus",
					namespace: "com.example",
					symbols: ["ACTIVE", "ON_LEAVE", "TERMINATED"]
				)
			)
		]
	)

	public static let avroSchemaString = """
		{
		  "type": "record",
		  "name": "Employee",
		  "namespace": "com.example",
		  "fields": [
		    {
		      "name": "id",
		      "type": "int"
		    },
		    {
		      "name": "name",
		      "type": "string"
		    },
		    {
		      "name": "department",
		      "type": {
		        "type": "enum",
		        "name": "Department",
		        "symbols": ["ENGINEERING", "SALES", "MARKETING", "HR", "FINANCE"]
		      }
		    },
		    {
		      "name": "status",
		      "type": {
		        "type": "enum",
		        "name": "EmployeeStatus",
		        "symbols": ["ACTIVE", "ON_LEAVE", "TERMINATED"]
		      }
		    }
		  ]
		}
		"""

	public static let instance = Def(
		id: 12345,
		name: "Alice Johnson",
		department: .ENGINEERING,
		status: .ACTIVE
	)

	public static let serialized = Data([
		0xf2, 0xc0, 0x01, 0x1a, 0x41, 0x6c, 0x69, 0x63, 0x65, 0x20, 0x4a, 0x6f, 0x68, 0x6e, 0x73, 0x6f, 0x6e, 0x00, 0x00
	])
}
