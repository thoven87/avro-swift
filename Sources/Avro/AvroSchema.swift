//
//  Schema.swift
//  avro-swift
//
//  Created by Felix Ruppert on 09.11.25.
//

/// An Avro Schema.
indirect public enum AvroSchema: Equatable, Sendable {
	case null, boolean, int, long, float, double, bytes, string
	// case fixed(name: String, size: Int)
	case `enum`(
		name: String,
		namespace: String? = nil,
		doc: String? = nil,
		aliases: [String]? = nil,
		symbols: [String],
		default: String? = nil
	)
	case array(items: AvroSchema)
	case map(values: AvroSchema)
	case record(name: String, namespace: String? = nil, doc: String? = nil, aliases: [String]? = nil, fields: [Field])
	// case union([AvroSchema])
	case logical(type: LogicalType, underlying: AvroSchema)
	//
	/// A field of an Avro schema.
	public struct Field: Equatable, Sendable {
		/// The field name.
		public let name: String
		/// The doc of the field.
		public let doc: String? = nil
		/// The datatype.
		public let type: AvroSchema
		/// The order of the field.
		public let order: Order = .ignore
		/// Aliases of the field.
		public let aliases: [String]? = nil
		// FIXME: Defaults
		/// Initialize a new field.
		/// - Parameters:
		///   - name: The name of the field.
		///   - type: The type of the field.
		@inlinable
		@inline(__always)
		public init(name: String, type: AvroSchema) {
			self.name = name
			self.type = type

		}
	}
	/// The logical type of a field.
	public enum LogicalType: Equatable, Sendable {
		case date
		case timeMillis
		case timestampMillis
		case timeMicros
		case timestampMicros
		case uuid
		case decimal(scale: Int, precision: Int)
	}
	/// The order of the fields.
	public enum Order: Equatable, Sendable {
		case ascending
		case decending
		case ignore
	}
}
