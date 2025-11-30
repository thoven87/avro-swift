//
//  AvroProtocol.swift
//  avro-swift
//
//  Created by Felix Ruppert on 30.11.25.
//

public protocol AvroProtocol: Codable {
	static var avroSchemaString: String { get throws }
	static var avroSchema: AvroSchemaDefinition { get }
	func encode(to encoder: Encoder) throws

}
