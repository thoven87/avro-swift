//
//  AvroUnkeyedDecodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 15.11.25.
//

class AvroUnkeyedDecodingContainer: UnkeyedDecodingContainer {
	var codingPath: [CodingKey]
	var itemSchema: AvroSchema
	var reader: AvroReader
	var count: Int?
	var isAtEnd: Bool = false
	var currentIndex: Int = 0
	var remainingInBlock = 0
	var isInitialized = false

	init(reader: AvroReader, schema: AvroSchema, codingPath: [CodingKey]) {
		self.reader = reader
		self.itemSchema = schema
		self.codingPath = codingPath
	}

	func startOfBlock(withCount blockCount: Int64) {
		if blockCount == 0 {
			isAtEnd = true
		} else if blockCount < 0 {
			fatalError("Negative block sizes not implemented")
		} else {
			remainingInBlock = Int(blockCount)
			if count == nil {
				count = Int(blockCount)
			} else {
				count? += Int(blockCount)
			}
		}
	}

	func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
		if !isInitialized {
			let blockCount = try reader.readLong()
			startOfBlock(withCount: blockCount)
			isInitialized = true
		}
		guard !isAtEnd else {
			throw DecodingError.dataCorrupted(
				.init(
					codingPath: codingPath,
					debugDescription: "Tried to decode a value from an unkeyed container that has already reached its end."
				)
			)
		}
		currentIndex += 1
		remainingInBlock -= 1
		let box = _AvroDecodingBox(schema: itemSchema, reader: reader, codingPath: codingPath)
		let value = try T(from: box)
		if remainingInBlock == 0 {
			startOfBlock(withCount: try reader.readLong())
		}
		return value
	}

	func decodeNil() throws -> Bool {
		fatalError()
	}
	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
	where NestedKey: CodingKey {
		fatalError()
	}
	func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
		fatalError()
	}
	func superDecoder() throws -> any Decoder {
		fatalError()
	}
}
