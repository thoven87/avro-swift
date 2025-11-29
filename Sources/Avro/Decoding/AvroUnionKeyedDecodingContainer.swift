//
//  AvroUnionKeyedDecodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 15.11.25.
//

class AvroUnionKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
	var codingPath: [CodingKey]
	var unionSchemas: [AvroSchemaDefinition]
	var reader: AvroReader
	var count: Int?
	var unionIndex: Int?

	var allKeys: [Key] {
		do {
			let index = try reader.readLong()
			self.unionIndex = Int(index)
			let schema = unionSchemas[Int(index)]
			if let key = Key(intValue: Int(index)) {
				return [key]
			}
			let schemaName: String
			switch schema {
				case .record(let name, _, _, _, _):
					schemaName = name
				case .enum(let name, _, _, _, _, _):
					schemaName = name
				default:
					schemaName = "\(schema)"
			}
			// Convert to camelCase for enum case matching
			let camelCaseName = schemaName.prefix(1).lowercased() + schemaName.dropFirst()
			guard let key = Key(stringValue: camelCaseName) else {
				fatalError("Failed to create key from schema name: \(camelCaseName)")
			}
			return [key]
		} catch {
			fatalError("Invalid key index")
		}
	}

	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
		guard let unionIndex else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(codingPath: codingPath, debugDescription: "Index of union not set")
			)
		}
		let schema = unionSchemas[unionIndex]
		let decoder = _AvroDecodingBox(schema: schema, reader: reader, codingPath: codingPath)
		return try T(from: decoder)
	}

	init(reader: AvroReader, unionSchemas: [AvroSchemaDefinition], codingPath: [CodingKey], unionIndex: Int? = nil) {
		self.reader = reader
		self.unionSchemas = unionSchemas
		self.codingPath = codingPath
		self.unionIndex = unionIndex
	}

	func contains(_ key: Key) -> Bool { fatalError() }

	func decodeNil(forKey key: Key) throws -> Bool {
		true
	}

	func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
	where NestedKey: CodingKey {
		let decoder = AvroUnionKeyedDecodingContainer<NestedKey>(
			reader: reader,
			unionSchemas: unionSchemas,
			codingPath: codingPath,
			unionIndex: self.unionIndex
		)
		return .init(decoder)
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
