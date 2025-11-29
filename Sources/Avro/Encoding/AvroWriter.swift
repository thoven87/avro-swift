//
//  AvroWriter.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Foundation

final class AvroWriter {
	private(set) var buffer = Data()

	var data: Data {
		buffer
	}

	@inline(__always)
	private func zigZagEncode(_ value: Int64) -> UInt64 {
		UInt64(bitPattern: (value << 1) ^ (value >> 63))
	}

	@inline(__always)
	private func zigZagEncode(_ value: Int32) -> UInt32 {
		UInt32(bitPattern: (value << 1) ^ (value >> 31))
	}

	func writeBoolean(_ value: Bool) {
		buffer.append(value ? 1 : 0)
	}

	func writeRaw(_ value: UInt8) {
		buffer.append(value)
	}

	func writeRawBlock(_ value: [UInt8]) {
		buffer.append(contentsOf: value)
	}

	func writeRawData(_ value: Data) {
		buffer.append(value)
	}

	func writeInt(_ value: Int32) {
		let zz = UInt64(zigZagEncode(value))
		writeVarUInt(zz)
	}

	@inlinable
	@inline(__always)
	func writeLong(_ value: Int64) {
		let zz = zigZagEncode(value)
		writeVarUInt(zz)
	}

	func writeFloat(_ value: Float) {
		var le = value.bitPattern.littleEndian // UInt32
		withUnsafeBytes(of: &le) { bytes in
			buffer.append(contentsOf: bytes)
		}
	}

	func writeDouble(_ value: Double) {
		var le = value.bitPattern.littleEndian // UInt64
		withUnsafeBytes(of: &le) { bytes in
			buffer.append(contentsOf: bytes)
		}
	}

	func writeBytes(_ value: Data) {
		writeLong(Int64(value.count))
		buffer.append(value)
	}

	func writeString(_ value: String) {
		let utf8Bytes = value.data(using: .utf8)!
		writeLong(Int64(utf8Bytes.count))
		buffer.append(utf8Bytes)
	}

	@inline(__always)
	private func writeVarUInt(_ value: UInt64) {
		#if compiler(>=6.2)
			// Swift 6.2+ compilers

			#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
				if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, *) {
					writeVarUInt_inlineArray(value)
				} else {
					writeVarUInt_fallback(value)
				}
			#else
				writeVarUInt_inlineArray(value)
			#endif

		#else
			writeVarUInt_fallback(value)
		#endif
	}

	@inline(__always)
	private func writeVarUInt_fallback(_ value: UInt64) {
		var v = value
		while (v & ~0x7F) != 0 {
			buffer.append(UInt8((v & 0x7F) | 0x80))
			v >>= 7
		}
		buffer.append(UInt8(v & 0x7F))
	}

	#if compiler(>=6.2)
		@available(iOS 26.0, macOS 26.0, watchOS 26, tvOS 26, *)
		@inline(__always)
		private func writeVarUInt_inlineArray(_ value: UInt64) {
			var tmp: InlineArray<10, UInt8> = .init(repeating: 0)
			var count = 0
			var v = value

			while (v & ~0x7F) != 0 {
				tmp[count] = UInt8((v & 0x7F) | 0x80)
				count += 1
				v >>= 7
			}
			tmp[count] = UInt8(v & 0x7F)
			count += 1

			let s = tmp.span
			for i in 0 ..< count {
				buffer.append(s[i])
			}
		}
	#endif

}
