//
//  AvroEncoder.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

/// An encoder to encode a ``Schema()`` object into `Data`.
public final class AvroEncoder {
	var schema: AvroSchemaDefinition

	/// Initialize a new encoder.
	/// - Parameter schema: The schema to use for encoding.
	public init(schema: AvroSchemaDefinition) {
		self.schema = schema
	}

	/// Encode an object.
	/// - Parameter value: The object to encode.
	/// - Returns: The encoded object.
	/// - Throws: The encoding error.
	public func encode<T: Encodable>(_ value: T) throws -> Data {
		var writer = AvroWriter()
		let box = _AvroEncodingBox(schema: schema, codingPath: [], userInfo: [:], writer: &writer)
		try value.encode(to: box)
		return writer.data
	}
}

final class _AvroEncodingBox: Encoder {
	var codingPath: [any CodingKey]
	var userInfo: [CodingUserInfoKey: Any] = [:]
	var writer: AvroWriter
	var schema: AvroSchemaDefinition

	init(schema: AvroSchemaDefinition, codingPath: [any CodingKey], userInfo: [CodingUserInfoKey: Any], writer: inout AvroWriter)
	{
		self.codingPath = codingPath
		self.userInfo = userInfo
		self.writer = writer
		self.schema = schema
	}

	func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
		switch schema {
			case .record(_, _, _, _, let fields):
				let container = AvroRecordKeyedEncodingContainer<Key>(fields: fields, writer: &writer, codingPath: codingPath)
				return .init(container)
			case .map(let valueSchema):
				let real = AvroMapKeyedEncodingContainer<Key>(field: valueSchema, writer: &writer, codingPath: codingPath)
				return .init(FinalizingMapKeyedContainer(base: real))
			case .union(let unionSchemas):
				let container = AvroUnionKeyedEncodingContainer<Key>(
					unionSchema: unionSchemas,
					writer: &writer,
					codingPath: codingPath
				)
				return .init(container)
			default:
				fatalError("Keyed container only for records and maps")
		}

	}

	func unkeyedContainer() -> UnkeyedEncodingContainer {
		switch schema {
			case .array(let items):
				let real = AvroUnkeyedEncodingContainer(codingPath: codingPath, itemSchema: items, writer: writer)
				return FinalizingUnkeyedContainer(base: real)
			case .bytes:
				let real = AvroUnkeyedEncodingContainer(codingPath: codingPath, itemSchema: .bytes, writer: writer, isBytes: true)
				return FinalizingUnkeyedContainer(base: real)
			default:
				preconditionFailure("Expected array or bytes for unkeyed container")
		}
	}

	func singleValueContainer() -> any SingleValueEncodingContainer {
		AvroSingleValueEncodingContainer(schema: schema, writer: &writer, codingPath: codingPath)

	}

	private final class FinalizingMapKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
		private let base: AvroMapKeyedEncodingContainer<Key>

		init(base: AvroMapKeyedEncodingContainer<Key>) {
			self.base = base
		}

		var codingPath: [CodingKey] {
			base.codingPath
		}

		var count: Int {
			base.count
		}

		func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
			try base.encode(value, forKey: key)
		}

		func encodeNil(forKey key: Key) throws {
			try base.encodeNil(forKey: key)
		}

		func nestedContainer<NestedKey>(keyedBy: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
			base.nestedContainer(keyedBy: keyedBy, forKey: key)
		}

		func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer { base.nestedUnkeyedContainer(forKey: key) }

		func superEncoder() -> Encoder { base.superEncoder() }

		func superEncoder(forKey key: Key) -> Encoder {
			base.superEncoder(forKey: key)
		}

		deinit {
			base.finalize()
		}
	}

	private final class FinalizingUnkeyedContainer: UnkeyedEncodingContainer {
		private let base: AvroUnkeyedEncodingContainer

		init(base: AvroUnkeyedEncodingContainer) {
			self.base = base
		}

		var codingPath: [CodingKey] {
			base.codingPath
		}

		var count: Int {
			base.count
		}

		func encode<T>(_ value: T) throws where T: Encodable {
			try base.encode(value)
		}

		func encodeNil() throws {
			try base.encodeNil()
		}

		func nestedContainer<NestedKey>(keyedBy: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
			base.nestedContainer(keyedBy: NestedKey.self)
		}

		func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
			base.nestedUnkeyedContainer()
		}

		func superEncoder() -> Encoder {
			base.superEncoder()
		}

		deinit {
			base.finalize()
		}
	}
}
