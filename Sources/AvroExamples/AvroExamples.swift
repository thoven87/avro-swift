//
//  AvroExamples.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

import Avro
import Foundation

@main
struct AvroExamples {
	static func main() throws {
		let user = User(name: "John Doe", age: 22, dob: Date(), username: "johndoe", address: Address(street: "John Doe Street"))
		let decodedAvro = try AvroEncoder(schema: User.avroSchema).encode(user)
		let _ = try AvroDecoder(schema: User.avroSchema).decode(User.self, from: decodedAvro)
	}
}

@AvroSchema
struct User: Codable {
	let name: String
	let age: Int
	@LogicalType(.date) let dob: Date
	let username: String
	let address: Address
}

@AvroSchema
struct Address: Codable {
	let street: String
}
