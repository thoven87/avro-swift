//
//  MessageUnionFixture.swift
//  avro-swift
//
//  Created by Felix Ruppert on 29.11.25.
//

import Avro
import Foundation

public enum MessageUnionFixture {

	@AvroSchema
	public struct TextPayload: Codable, Equatable, Sendable {
		let content: String
		let encoding: String
	}

	@AvroSchema
	public struct ImagePayload: Codable, Equatable, Sendable {
		let url: String
		let width: Int32
		let height: Int32
		let format: String
	}

	@AvroSchema
	public struct DataPayload: Codable, Equatable, Sendable {
		let data: Data
		let mimeType: String
	}

	@AvroUnion
	public enum Payload: Codable, Equatable, Sendable {
		case textPayload(TextPayload)
		case imagePayload(ImagePayload)
		case dataPayload(DataPayload)
	}

	@AvroSchema
	public struct Message: Codable, Equatable, Sendable {
		let messageId: String
		let timestamp: Int64
		let payload: Payload
		let sender: String?
	}

	public static let schema: AvroSchemaDefinition = .record(
		name: "Message",
		namespace: "com.example.messaging",
		fields: [
			.init(name: "messageId", type: .string),
			.init(name: "timestamp", type: .long),
			.init(
				name: "payload",
				type: .union([
					.record(
						name: "TextPayload",
						namespace: nil,
						fields: [
							.init(name: "content", type: .string),
							.init(name: "encoding", type: .string)
						]
					),
					.record(
						name: "ImagePayload",
						namespace: nil,
						fields: [
							.init(name: "url", type: .string),
							.init(name: "width", type: .int),
							.init(name: "height", type: .int),
							.init(name: "format", type: .string)
						]
					),
					.record(
						name: "DataPayload",
						namespace: nil,
						fields: [
							.init(name: "data", type: .bytes),
							.init(name: "mimeType", type: .string)
						]
					)
				])
			),
			.init(name: "sender", type: .union([.null, .string]))
		]
	)

	public static let avroSchemaString = """
		{
		  "type": "record",
		  "name": "Message",
		  "namespace": "com.example.messaging",
		  "doc": "Message that can contain different payload types",
		  "fields": [
		    {
		      "name": "messageId",
		      "type": "string"
		    },
		    {
		      "name": "timestamp",
		      "type": "long"
		    },
		    {
		      "name": "payload",
		      "type": [
		        {
		          "type": "record",
		          "name": "TextPayload",
		          "fields": [
		            {
		              "name": "content",
		              "type": "string"
		            },
		            {
		              "name": "encoding",
		              "type": "string"
		            }
		          ]
		        },
		        {
		          "type": "record",
		          "name": "ImagePayload",
		          "fields": [
		            {
		              "name": "url",
		              "type": "string"
		            },
		            {
		              "name": "width",
		              "type": "int"
		            },
		            {
		              "name": "height",
		              "type": "int"
		            },
		            {
		              "name": "format",
		              "type": "string"
		            }
		          ]
		        },
		        {
		          "type": "record",
		          "name": "DataPayload",
		          "fields": [
		            {
		              "name": "data",
		              "type": "bytes"
		            },
		            {
		              "name": "mimeType",
		              "type": "string"
		            }
		          ]
		        }
		      ],
		      "doc": "Union of different payload types"
		    },
		    {
		      "name": "sender",
		      "type": ["null", "string"],
		      "default": null
		    }
		  ]
		}
		"""

	public static let textMessageInstance = Message(
		messageId: "msg-001",
		timestamp: 1_700_000_000_000,
		payload: .textPayload(TextPayload(content: "Hello, World!", encoding: "UTF-8")),
		sender: "user@example.com"
	)

	public static let imageMessageInstance = Message(
		messageId: "msg-002",
		timestamp: 1_700_000_001_000,
		payload: .imagePayload(
			ImagePayload(
				url: "https://example.com/image.jpg",
				width: 1920,
				height: 1080,
				format: "JPEG"
			)
		),
		sender: nil
	)

	public static let dataMessageInstance = Message(
		messageId: "msg-003",
		timestamp: 1_700_000_002_000,
		payload: .dataPayload(
			DataPayload(
				data: Data([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
				mimeType: "application/octet-stream"
			)
		),
		sender: "system"
	)

	public static let textMessageSerialized = Data([
		0x0e, 0x6d, 0x73, 0x67, 0x2d, 0x30, 0x30, 0x31, 0x80, 0xa0, 0xab, 0xfe, 0xf9, 0x62, 0x00, 0x1a,
		0x48, 0x65, 0x6c, 0x6c, 0x6f, 0x2c, 0x20, 0x57, 0x6f, 0x72, 0x6c, 0x64, 0x21, 0x0a, 0x55, 0x54,
		0x46, 0x2d, 0x38, 0x02, 0x20, 0x75, 0x73, 0x65, 0x72, 0x40, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c,
		0x65, 0x2e, 0x63, 0x6f, 0x6d
	])

	public static let imageMessageSerialized = Data([
		0x0e, 0x6d, 0x73, 0x67, 0x2d, 0x30, 0x30, 0x32, 0xd0, 0xaf, 0xab, 0xfe, 0xf9, 0x62, 0x02, 0x3a,
		0x68, 0x74, 0x74, 0x70, 0x73, 0x3a, 0x2f, 0x2f, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e,
		0x63, 0x6f, 0x6d, 0x2f, 0x69, 0x6d, 0x61, 0x67, 0x65, 0x2e, 0x6a, 0x70, 0x67, 0x80, 0x1e, 0xf0,
		0x10, 0x08, 0x4a, 0x50, 0x45, 0x47, 0x00
	])

	public static let dataMessageSerialized = Data([
		0x0e, 0x6d, 0x73, 0x67, 0x2d, 0x30, 0x30, 0x33, 0xa0, 0xbf, 0xab, 0xfe, 0xf9, 0x62, 0x04, 0x10,
		0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x30, 0x61, 0x70, 0x70, 0x6c, 0x69, 0x63, 0x61,
		0x74, 0x69, 0x6f, 0x6e, 0x2f, 0x6f, 0x63, 0x74, 0x65, 0x74, 0x2d, 0x73, 0x74, 0x72, 0x65, 0x61,
		0x6d, 0x02, 0x0c, 0x73, 0x79, 0x73, 0x74, 0x65, 0x6d
	])
}
