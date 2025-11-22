//
//  AvroSingleValueEncodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

struct AvroSingleValueEncodingContainer: SingleValueEncodingContainer {
	var schema: AvroSchema
	var writer: AvroWriter
	var codingPath: [any CodingKey]

	init(schema: AvroSchema, writer: inout AvroWriter, codingPath: [any CodingKey]) {
		self.schema = schema
		self.writer = writer
		self.codingPath = codingPath
	}

	mutating func encode<T>(_ value: T) throws where T: Encodable {
		switch schema {
			case .null:
				try encodeNil()
			case .boolean:
				writer.writeBoolean(value as! Bool)
			case .int:
				if let v = value as? Int {
					writer.writeInt(Int32(v))
				} else if let v = value as? Int32 {
					writer.writeInt(v)
				} else {
					throw EncodingError.invalidValue(
						value,
						EncodingError.Context(codingPath: codingPath, debugDescription: "Expected Int")
					)
				}
			case .long:
				writer.writeLong(value as! Int64)
			case .float:
				writer.writeFloat(value as! Float)
			case .double:
				writer.writeDouble(value as! Double)
			case .bytes:
				writer.writeBytes(value as! Data)
			case .string:
				writer.writeString(value as! String)
			case .logical(let logicalType, _):
				try encodeLogical(value, as: logicalType)
			case .enum(_, _, _, _, let symbols, _):
				guard let i = symbols.firstIndex(of: value as! String) else {
					throw EncodingError.invalidValue(
						value,
						EncodingError.Context(codingPath: codingPath, debugDescription: "Value not in enum")
					)
				}
				writer.writeInt(Int32(i))

			default:
				fatalError("Unsupported schema for single value encoding: \(schema)")
		}
	}

	private func encodeLogical<T: Encodable>(_ v: T, as lt: AvroSchema.LogicalType) throws {

		switch lt {
			case .date:
				let referenceOffset: TimeInterval = 978307200.0

				let timestamp: TimeInterval
				if let d = v as? Date {
					timestamp = d.timeIntervalSince1970
				} else if let secondsSince2001 = v as? Double {
					timestamp = secondsSince2001 + referenceOffset
				} else {
					throw EncodingError.invalidValue(
						v,
						EncodingError.Context(
							codingPath: codingPath,
							debugDescription: "Cannot encode value as Date or Double timestamp"
						)
					)
				}
				let days = Int64(floor(timestamp / 86400.0))
				writer.writeInt(Int32(truncatingIfNeeded: days))
				return

			case .timestampMillis:
				fatalError("Timestamp millis logical type not implemented")

			case .timestampMicros:
				fatalError("Timestamp micros logical type not implemented")

			case .timeMillis:
				if let value = v as? Int {
					writer.writeInt(Int32(value))
				} else if let value = v as? Int32 {
					writer.writeInt(value)
				} else {
					throw EncodingError.invalidValue(
						v,
						EncodingError.Context(codingPath: codingPath, debugDescription: "Can only encode Int or Int32")
					)
				}

			case .timeMicros:
				if let value = v as? Int {
					writer.writeLong(Int64(value))
				} else if let value = v as? Int64 {
					writer.writeLong(value)
				} else {
					throw EncodingError.invalidValue(
						v,
						EncodingError.Context(codingPath: codingPath, debugDescription: "Can only encode Int or Int32")
					)
				}

			case .uuid:
				if let value = v as? UUID {
					writer.writeString(value.uuidString)
				} else if let value = v as? String {
					let uuidCheck = UUID(uuidString: value)
					guard uuidCheck != nil else {
						throw EncodingError.invalidValue(
							v,
							EncodingError.Context(codingPath: codingPath, debugDescription: "Invalid UUID string")
						)
					}
					writer.writeString(value)
				} else {
					throw EncodingError.invalidValue(
						v,
						EncodingError.Context(codingPath: codingPath, debugDescription: "Can only encode UUID or String")
					)
				}

			case .decimal(_, _):
				fatalError("Decimal logical type not implemented")
		}
	}

	mutating func encodeNil() throws {
		return
	}

}
