//
//  AvroKeyedDecodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

struct AvroRecordKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
	var codingPath: [CodingKey]
	var fields: [AvroSchemaDefinition.Field]
	var reader: AvroReader
	var allKeys: [Key] { fields.compactMap { Key(stringValue: $0.name) } }

	init(fields: [AvroSchemaDefinition.Field], reader: inout AvroReader, codingPath: [CodingKey]) {
		self.fields = fields
		self.reader = reader
		self.codingPath = codingPath
	}

	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
		guard let field = fields.first(where: { $0.name == key.stringValue }) else {
			throw DecodingError.valueNotFound(
				type,
				.init(codingPath: codingPath, debugDescription: "Unknown field: \(key.stringValue)")
			)
		}
		let box = _AvroDecodingBox(schema: field.type, reader: reader, codingPath: codingPath + [key])
		return try T(from: box)
	}

	func contains(_ key: Key) -> Bool { fields.contains { $0.name == key.stringValue } }

	func decodeNil(forKey key: Key) throws -> Bool {
		guard let field = fields.first(where: { $0.name == key.stringValue }) else {
			throw DecodingError.valueNotFound(
				Any?.self,
				.init(codingPath: codingPath, debugDescription: "Unknown field: \(key.stringValue)")
			)
		}
		switch field.type {
			case .union(let schemas):
				let savedOffset = reader.currentOffset
				let index = Int(try reader.readLong())
				reader.seek(to: savedOffset)

				guard index < schemas.count else {
					throw DecodingError.dataCorrupted(
						.init(codingPath: codingPath + [key], debugDescription: "Union index out of bounds")
					)
				}
				if case .null = schemas[index] {
					return true
				}
				return false
			default:
				return true
		}
	}

	func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
	where NestedKey: CodingKey {
		fatalError()
	}

	func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
		fatalError()
	}

	func superDecoder() throws -> any Decoder {
		fatalError()
	}

	func superDecoder(forKey key: Key) throws -> any Decoder {
		fatalError()
	}

}
