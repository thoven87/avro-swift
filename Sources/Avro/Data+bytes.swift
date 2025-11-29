//
//  Data+bytes.swift
//  avro-swift
//
//  Created by Felix Ruppert on 29.11.25.
//

//Backporting bytes for compilers < 6.2
#if compiler(<6.2)
	import Foundation

	@available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, *)
	public var bytes: RawSpan {
		@lifetime(borrow self)
		borrowing get {
			let buffer: UnsafeRawBufferPointer
			switch _representation {
				case .empty:
					buffer = UnsafeRawBufferPointer(start: nil, count: 0)
				case .inline(let inline):
					buffer = unsafe UnsafeRawBufferPointer(
						start: UnsafeRawPointer(Builtin.addressOfBorrow(self)),
						count: inline.count
					)
				case .large(let slice):
					buffer = unsafe UnsafeRawBufferPointer(
						start: slice.storage.mutableBytes?.advanced(by: slice.startIndex),
						count: slice.count
					)
				case .slice(let slice):
					buffer = unsafe UnsafeRawBufferPointer(
						start: slice.storage.mutableBytes?.advanced(by: slice.startIndex),
						count: slice.count
					)
			}
			let span = unsafe RawSpan(_unsafeBytes: buffer)
			return unsafe _overrideLifetime(span, borrowing: self)
		}
	}
#endif
