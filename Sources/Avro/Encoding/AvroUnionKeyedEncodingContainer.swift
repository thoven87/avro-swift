//
//  AvroKeyedEncodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

final class AvroUnionKeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
	var codingPath: [CodingKey]
	var writer: AvroWriter
	var count: Int = 0
	var unionSchema: [AvroSchemaDefinition]

	init(unionSchema: [AvroSchemaDefinition], writer: inout AvroWriter, codingPath: [CodingKey]) {
		self.writer = writer
		self.codingPath = codingPath
		self.unionSchema = unionSchema
	}

	func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
		var pos = 0
		while pos < unionSchema.count {
			var tempWriter = AvroWriter()
			let box = _AvroEncodingBox(schema: unionSchema[pos], codingPath: codingPath, userInfo: [:], writer: &tempWriter)
			tempWriter.writeLong(Int64(pos))
			do {
				try value.encode(to: box)
				writer.writeRawBlock(tempWriter.data.map { UInt8($0) })
				break
			} catch {
				pos += 1
				continue
			}
		}
	}

	func encodeNil(forKey key: Key) throws { try encode(Optional<Int>.none, forKey: key) }

	func contains(_ key: Key) -> Bool { fatalError() }

	func nestedContainer<NestedKey>(keyedBy: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
		let encoder = AvroUnionKeyedEncodingContainer<NestedKey>(
			unionSchema: unionSchema,
			writer: &writer,
			codingPath: codingPath
		)
		return .init(encoder)
	}
	func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { fatalError() }
	func superEncoder() -> Encoder { fatalError() }
	func superEncoder(forKey key: Key) -> Encoder { fatalError() }
}
