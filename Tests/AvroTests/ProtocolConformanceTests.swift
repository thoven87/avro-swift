//
//  ProtocolConformanceTests.swift
//  avro-swift
//
//  Created by Felix Ruppert on 30.11.25.
//

import Avro
import Testing

@Suite("Protocol Conformance Tests")
struct ProtocolConformanceTests {

	@AvroSchema
	struct TestRecord: Codable {
		let id: Int
		let name: String
	}

	@Test("@AvroSchema types conform to AvroProtocol")
	func testAvroProtocolConformance() {
		// This will only compile if TestRecord conforms to AvroProtocol
		let _: any AvroProtocol = TestRecord(id: 1, name: "Test")

		// Verify at runtime
		#expect(TestRecord(id: 1, name: "Test") is AvroProtocol)
	}
}
