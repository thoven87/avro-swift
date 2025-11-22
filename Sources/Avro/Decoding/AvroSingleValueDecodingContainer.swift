//
//  AvroSingleValueDecodingContainer.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

struct AvroSingleValueDecodingContainer: SingleValueDecodingContainer {
	var schema: AvroSchema
	var reader: AvroReader
	var codingPath: [any CodingKey]

	init(schema: AvroSchema, reader: inout AvroReader, codingPath: [any CodingKey]) {
		self.schema = schema
		self.reader = reader
		self.codingPath = codingPath
	}

	func decodeNil() -> Bool {
		true
	}

	@inline(__always)
	private func int64FromAvroDecimalBytes(_ data: Data) -> Int64? {
		guard !data.isEmpty, data.count <= 8 else {
			return nil // too big for Int64 or empty
		}

		var value: Int64 = 0
		for byte in data {
			value = (value << 8) | Int64(UInt8(byte))
		}

		if data.count < 8 {
			let bits = data.count * 8
			let signBitIndex = bits - 1
			let signBitMask: Int64 = 1 << signBitIndex

			if (value & signBitMask) != 0 {
				let extensionMask: Int64 = ~((Int64(1) << bits) - 1)
				value |= extensionMask
			}
		}

		return value
	}

	func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
		switch schema {
			case .null:
				return decodeNil() as! T
			case .boolean:
				return try reader.readBoolean() as! T
			case .int:
				let value = try reader.readInt()
				guard T.self == Int.self else {
					return value as! T
				}
				return Int(value) as! T
			case .long:
				return try reader.readLong() as! T
			case .float:
				return try reader.readFloat() as! T
			case .double:
				return try reader.readDouble() as! T
			case .bytes:
				return try reader.readBytes() as! T
			case .string:
				return try reader.readString() as! T
			case .logical(let logicalType, _):
				return try decodeLogical(as: logicalType)
			case .enum(_, _, _, _, let symbols, _):
				return symbols[Int(try reader.readInt())] as! T
			default:
				throw DecodingError.typeMismatch(
					T.self,
					DecodingError.Context(codingPath: codingPath, debugDescription: "Unsupported schema")
				)
		}
	}

	private func decodeLogical<T>(as lt: AvroSchema.LogicalType) throws -> T {
		let referenceOffset: Double = -978307200.0

		switch lt {

			case .date:
				return try Double(reader.readInt()) * 86400 + referenceOffset as! T
			case .timeMillis:
				if T.self == Int.self {
					return try Int(reader.readInt()) as! T
				} else if T.self == Int32.self {
					return try reader.readInt() as! T
				} else {
					throw DecodingError.typeMismatch(
						T.self,
						DecodingError.Context(codingPath: codingPath, debugDescription: "Can only decode Int or Int32")
					)
				}
			case .timestampMillis:
				fatalError("Timestamp millis logical type not implemented")
			case .timeMicros:
				if T.self == Int.self {
					return try Int(reader.readLong()) as! T
				} else if T.self == Int64.self {
					return try reader.readLong() as! T
				} else {
					throw DecodingError.typeMismatch(
						T.self,
						DecodingError.Context(codingPath: codingPath, debugDescription: "Can only decode Int or Int64")
					)
				}
			case .timestampMicros:
				fatalError("timestampMicros logical type not implemented")
			case .uuid:
				if T.self == UUID.self {
					return UUID(uuidString: try reader.readString()) as! T
				} else if T.self == String.self {
					let value = try reader.readString()
					let uuidCheck = UUID(uuidString: value)
					guard uuidCheck != nil else {
						throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid UUID String")
					}
					return value as! T
				} else {
					throw DecodingError.typeMismatch(
						T.self,
						DecodingError.Context(codingPath: codingPath, debugDescription: "Can only decode UUID or String")
					)
				}
			case .decimal(let scale, let precision):
				guard T.self == Decimal.self else {
					throw DecodingError.typeMismatch(
						T.self,
						DecodingError.Context(
							codingPath: codingPath,
							debugDescription: "Can only decode Float, Decimal or Double"
						)
					)
				}
				let bytes = try reader.readBytes()
				guard let unscaled = int64FromAvroDecimalBytes(bytes) else {
					throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid Decimal")
				}
				var result = Decimal(unscaled)
				if scale > 0 {
					var divisor = Decimal(1)
					for _ in 0 ..< scale {
						divisor *= 10
					}
					result /= divisor
				}
				guard result.fits(precision: precision, scale: scale) else {
					throw DecodingError.typeMismatch(
						T.self,
						DecodingError.Context(codingPath: codingPath, debugDescription: "Scale or precision not matching")
					)
				}
				return result as! T

		}
	}

}
