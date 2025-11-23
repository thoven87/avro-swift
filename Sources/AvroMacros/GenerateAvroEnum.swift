//
//  GenerateAvroEnum.swift
//  avro-swift
//
//  Created by Felix Ruppert on 22.11.25.
//

import Foundation
import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro to automatically generate an Avro Schema for an enum.
public struct GenerateAvroEnum: MemberMacro {
	public static func expansion(
		of attribute: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			let diag = Diagnostic(
				node: Syntax(declaration),
				message: SimpleDiagnosticMessage(
					message: "@AvroEnum can only be applied to enums",
					severity: .error
				)
			)
			context.diagnose(diag)
			return []
		}

		let enumName = enumDecl.name.text

		// Extract namespace and doc from macro arguments if provided
		let (namespace, doc) = extractMacroArguments(from: attribute)

		// Extract enum cases
		var symbols: [String] = []

		for member in enumDecl.memberBlock.members {
			if let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) {
				for element in caseDecl.elements {
					// Only allow simple enums without associated values
					if element.parameterClause != nil {
						let diag = Diagnostic(
							node: Syntax(element),
							message: SimpleDiagnosticMessage(
								message: "@AvroEnum does not support enums with associated values",
								severity: .error
							)
						)
						context.diagnose(diag)
						return []
					}
					symbols.append(element.name.text)
				}
			}
		}

		guard !symbols.isEmpty else {
			let diag = Diagnostic(
				node: Syntax(enumDecl),
				message: SimpleDiagnosticMessage(
					message: "@AvroEnum requires at least one case",
					severity: .error
				)
			)
			context.diagnose(diag)
			return []
		}

		// Generate the avroSchema static property
		let symbolsArray = symbols.map { "\"\($0)\"" }.joined(separator: ", ")
		let namespaceParam = namespace.map { ", namespace: \"\($0)\"" } ?? ""
		let docParam = doc.map { ", doc: \"\($0)\"" } ?? ""

		let memberSource = """
			public static var avroSchema: AvroSchemaDefinition {
				.enum(name: "\(enumName)"\(namespaceParam)\(docParam), symbols: [\(symbolsArray)])
			}
			"""

		return [DeclSyntax(stringLiteral: memberSource)]
	}

	private static func extractMacroArguments(from attribute: AttributeSyntax) -> (namespace: String?, doc: String?) {
		guard let arguments = attribute.arguments,
			let labeledList = arguments.as(LabeledExprListSyntax.self)
		else {
			return (nil, nil)
		}

		var namespace: String? = nil
		var doc: String? = nil

		for argument in labeledList {
			guard let label = argument.label?.text else { continue }

			let value = argument.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
			let stringValue = extractStringLiteral(from: value)

			switch label {
				case "namespace":
					namespace = stringValue
				case "doc":
					doc = stringValue
				default:
					break
			}
		}

		return (namespace, doc)
	}

	private static func extractStringLiteral(from expression: String) -> String? {
		let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
			return String(trimmed.dropFirst().dropLast())
		}
		return nil
	}

	private struct SimpleDiagnosticMessage: DiagnosticMessage {
		let message: String
		let severity: DiagnosticSeverity
		var diagnosticID: MessageID { .init(domain: "GenerateAvroEnum", id: "enum-validation") }
		var messageText: String { message }
	}
}
