//
//  Decimal+fits.swift
//  avro-swift
//
//  Created by Felix Ruppert on 16.11.25.
//

import Foundation

extension Decimal {
	@inlinable
	@inline(__always)
	func fits(precision: Int, scale: Int) -> Bool {
		let string = self.description
		let parts = string.split(separator: ".", omittingEmptySubsequences: false)
		let integerPart = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "-"))
		let fractionalPart = parts.count > 1 ? parts[1] : ""

		let integerDigits = integerPart.count
		let fractionalDigits = fractionalPart.count

		if fractionalDigits > scale {
			return false
		}

		if integerDigits + fractionalDigits > precision {
			return false
		}

		return true
	}
}
