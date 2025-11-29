//
//  AvroReader.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

final class AvroReader {
	let data: Data
	private var offset: Int = 0

	var currentOffset: Int {
		offset
	}

	func seek(to position: Int) {
		offset = position
	}

	init(data: Data) {
		self.data = data
	}

	init(data: Data, offset: Int) {
		self.data = data
		self.offset = offset
	}

	@inline(__always)
	private func ensureAvailable(_ count: Int) throws {
		guard count >= 0, offset + count <= data.count else {
			throw AvroError.endOfData
		}
	}

	@inline(__always)
	private func readByte() throws -> UInt8 {
		try ensureAvailable(1)
		let value = data.bytes.unsafeLoadUnaligned(fromByteOffset: offset, as: UInt8.self)
		offset += 1
		return value
	}

	@inline(__always)
	private func loadInteger<T: FixedWidthInteger & BitwiseCopyable>(_ type: T.Type) throws -> T {
		let size = MemoryLayout<T>.size
		try ensureAvailable(size)
		let raw = data.bytes.unsafeLoadUnaligned(fromByteOffset: offset, as: T.self)
		offset &+= size
		return T(littleEndian: raw)
	}

	@inline(__always)
	private func readBytes(count: Int) throws -> Data {
		try ensureAvailable(count)
		let start = offset
		let end = offset + count
		offset = end
		return Data(data[start ..< end]) // Have to make new Data to reset the startIndex to 0
	}

	@inline(__always)
	private func readVarUInt() throws -> UInt64 {
		var shift: UInt64 = 0
		var result: UInt64 = 0

		while true {
			let byte = try readByte()
			result |= UInt64(byte & 0x7F) << shift
			if (byte & 0x80) == 0 {
				break
			}
			shift += 7
			if shift > 63 {
				throw AvroError.integerOverflow
			}
		}
		return result
	}

	@inline(__always)
	private func zigZagDecodeInt(_ n: UInt32) -> Int32 {
		let shifted = Int32(bitPattern: n >> 1)
		let negMask = Int32(n & 1)
		return shifted ^ -negMask
	}

	@inline(__always)
	private func zigZagDecodeLong(_ n: UInt64) -> Int64 {
		let shifted = Int64(bitPattern: n >> 1)
		let negMask = Int64(n & 1)
		return shifted ^ -negMask
	}

	func readBoolean() throws -> Bool {
		let byte = try readByte()
		return byte != 0
	}

	func readInt() throws -> Int32 {
		let u = try readVarUInt()
		return zigZagDecodeInt(UInt32(u))
	}

	@inline(__always)
	@inlinable
	func readLong() throws -> Int64 {
		let u = try readVarUInt()
		return zigZagDecodeLong(u)
	}

	func readFloat() throws -> Float {
		let bits: UInt32 = try loadInteger(UInt32.self)
		return Float(bitPattern: bits)
	}

	func readDouble() throws -> Double {
		let bits: UInt64 = try loadInteger(UInt64.self)
		return Double(bitPattern: bits)
	}

	func readBytes() throws -> Data {
		let length = try readLong()
		guard length >= 0 else { throw AvroError.negativeLength }
		return try readBytes(count: Int(length))
	}

	func readString() throws -> String {
		let bytes = try readBytes()
		guard let str = String(data: bytes, encoding: .utf8) else {
			throw AvroError.invalidUTF8
		}
		return str
	}

	func skip(schema: AvroSchemaDefinition) throws {
		switch schema {
			case .null:
				break
			case .boolean:
				_ = try readByte()
			case .int:
				_ = try readInt()
			case .long:
				_ = try readLong()
			case .float:
				try ensureAvailable(4)
				offset &+= 4
			case .double:
				try ensureAvailable(8)
				offset &+= 8
			case .bytes:
				let length = try readLong()
				guard length >= 0 else { throw AvroError.negativeLength }
				try ensureAvailable(Int(length))
				offset &+= Int(length)
			case .string:
				let length = try readLong()
				guard length >= 0 else { throw AvroError.negativeLength }
				try ensureAvailable(Int(length))
				offset &+= Int(length)
			case .array(let items):
				var isAtEnd = false
				while !isAtEnd {
					let blockCount = try readLong()
					if blockCount == 0 {
						isAtEnd = true
					} else if blockCount < 0 {
						_ = try readLong()
						let count = Int(-blockCount)
						for _ in 0 ..< count {
							try skip(schema: items)
						}
					} else {
						let count = Int(blockCount)
						for _ in 0 ..< count {
							try skip(schema: items)
						}
					}
				}
			case .map(let values):
				var isAtEnd = false
				while !isAtEnd {
					let blockCount = try readLong()
					if blockCount == 0 {
						isAtEnd = true
					} else if blockCount < 0 {
						_ = try readLong()
						let count = Int(-blockCount)
						for _ in 0 ..< count {
							_ = try readString()
							try skip(schema: values)
						}
					} else {
						let count = Int(blockCount)
						for _ in 0 ..< count {
							_ = try readString()
							try skip(schema: values)
						}
					}
				}
			case .record(_, _, _, _, let fields):
				for field in fields {
					try skip(schema: field.type)
				}
			case .logical(_, let underlying):
				try skip(schema: underlying)
			case .enum:
				_ = try readInt()
			case .union:
				// FIXME: Implement skipping of unions
				fatalError()
		}
	}
}
