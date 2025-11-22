//
//  GeneralTests.swift
//  avro-swift
//
//  Created by Felix Ruppert on 16.11.25.
//

import Foundation
import Testing

@testable import Avro

@Suite("General Tests")
struct GeneralTests {

	@Test("Decimal precision true")
	func decimalPrecisionTrue() {
		let value: Decimal = 3.12
		#expect(value.fits(precision: 3, scale: 2))
	}

	@Test("Decimal precision false")
	func decimalPrecisionFalse() {
		let value: Decimal = 3.123
		#expect(!value.fits(precision: 3, scale: 2))
	}
}
