//
//  GenerateAvroUnion.swift
//  avro-swift
//
//  Created by Felix Ruppert on 23.11.25.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro to automatically generate an Avro Schema for a union type.
public struct GenerateAvroUnion: MemberMacro {
	public static func expansion(
		of attribute: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			let diag = Diagnostic(
				node: Syntax(declaration),
				message: SimpleDiagnosticMessage(
					message: "@AvroUnion can only be applied to enums",
					severity: .error
				)
			)
			context.diagnose(diag)
			return []
		}

		// Extract union schemas from enum cases
		var unionSchemas: [String] = []

		for member in enumDecl.memberBlock.members {
			if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
				for element in caseDecl.elements {
					// Check if the case has an associated value
					guard let parameterClause = element.parameterClause else {
						let diag = Diagnostic(
							node: Syntax(element),
							message: SimpleDiagnosticMessage(
								message: "@AvroUnion requires all cases to have an associated value",
								severity: .error
							)
						)
						context.diagnose(diag)
						return []
					}
					// Extract the type from the associated value
					guard let parameter = parameterClause.parameters.first else {
						let diag = Diagnostic(
							node: Syntax(element),
							message: SimpleDiagnosticMessage(
								message: "@AvroUnion requires exactly one associated value per case",
								severity: .error
							)
						)
						context.diagnose(diag)
						return []
					}

					if parameterClause.parameters.count > 1 {
						let diag = Diagnostic(
							node: Syntax(element),
							message: SimpleDiagnosticMessage(
								message:
									"@AvroUnion requires exactly one associated value per case, found \(parameterClause.parameters.count)",
								severity: .error
							)
						)
						context.diagnose(diag)
						return []
					}

					let typeName = parameter.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
					let schema = mapToAvroSchema(typeName)
					unionSchemas.append(schema)
				}
			}
		}

		guard !unionSchemas.isEmpty else {
			let diag = Diagnostic(
				node: Syntax(enumDecl),
				message: SimpleDiagnosticMessage(
					message: "@AvroUnion requires at least one case with an associated value",
					severity: .error
				)
			)
			context.diagnose(diag)
			return []
		}

		// Generate the avroSchema static property
		let schemasArray = unionSchemas.joined(separator: ", ")

		let memberSource = """
			public static var avroSchema: AvroSchemaDefinition {
				.union([\(schemasArray)])
			}
			"""

		return [DeclSyntax(stringLiteral: memberSource)]
	}

	private static func mapToAvroSchema(_ typeName: String) -> String {
		let type = typeName.trimmingCharacters(in: .whitespacesAndNewlines)

		switch type {
			case "Null", "()":
				return ".null"
			case "Int", "Int32":
				return ".int"
			case "Int64":
				return ".long"
			case "Float":
				return ".float"
			case "Double":
				return ".double"
			case "Bool":
				return ".boolean"
			case "String":
				return ".string"
			case "Data", "[UInt8]":
				return ".bytes"
			default:
				// Check for array or map
				if let nested = resolveNested(type: type) {
					return nested
				}
				// Otherwise, assume it's a custom type with its own avroSchema
				return "\(type).avroSchema"
		}
	}

	private static func resolveNested(type: String) -> String? {
		// Normalize whitespace
		let t = type.trimmingCharacters(in: .whitespacesAndNewlines)
		guard t.hasPrefix("[") && t.hasSuffix("]") else { return nil }

		// Strip outer brackets
		let inner = String(t.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)

		// Determine if this is an array [T] or a dictionary [K: V] at the top level.
		func topLevelColonIndex(in s: String) -> String.Index? {
			var depth = 0
			var idx = s.startIndex
			while idx < s.endIndex {
				let ch = s[idx]
				if ch == "[" { depth += 1 } else if ch == "]" { depth -= 1 } else if ch == ":" && depth == 0 { return idx }
				idx = s.index(after: idx)
			}
			return nil
		}

		guard let colon = topLevelColonIndex(in: inner) else {
			// Array [T]
			let elementSchema = mapToAvroSchema(inner)
			return ".array(items: \(elementSchema))"
		}

		let valuePart = inner[inner.index(after: colon)...].trimmingCharacters(in: .whitespacesAndNewlines)
		let valueSchema = mapToAvroSchema(valuePart)
		return ".map(values: \(valueSchema))"
	}

	private struct SimpleDiagnosticMessage: DiagnosticMessage {
		let message: String
		let severity: DiagnosticSeverity
		var diagnosticID: MessageID { .init(domain: "GenerateAvroUnion", id: "union-validation") }
		var messageText: String { message }
	}
}
