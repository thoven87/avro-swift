//
//  AvroUnkeyedEncodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 13.11.25.
//

class AvroUnkeyedEncodingContainer: UnkeyedEncodingContainer {
	var codingPath: [CodingKey]
	var count: Int = 0
	var itemSchema: AvroSchema
	var writer: AvroWriter
	var tempWriter = AvroWriter()
	private var finalized = false

	init(codingPath: [CodingKey], itemSchema: AvroSchema, writer: AvroWriter) {
		self.codingPath = codingPath
		self.itemSchema = itemSchema
		self.writer = writer
	}

	func encode<T>(_ value: T) throws where T: Encodable {
		let box = _AvroEncodingBox(schema: itemSchema, codingPath: codingPath, userInfo: [:], writer: &tempWriter)
		try value.encode(to: box)
		count += 1
	}

	func finalize() {
		guard !finalized else { return }
		writer.writeLong(Int64(count)) // Length
		writer.writeRawBlock(tempWriter.data.map { UInt8($0) })
		writer.writeLong(0) // Termination
		finalized = true
	}

	deinit {
		if !finalized {
			assertionFailure("UnkeyedEncodingContainer was discarded before finalize() was called")
		}
	}

	func encodeNil() throws { fatalError() }
	func nestedContainer<NestedKey>(keyedBy: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> { fatalError() }
	func nestedUnkeyedContainer() -> UnkeyedEncodingContainer { fatalError() }
	func superEncoder() -> Encoder { fatalError() }
}
