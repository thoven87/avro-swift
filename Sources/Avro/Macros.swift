@attached(member, names: arbitrary)
@attached(extension, conformances: AvroProtocol)
public macro AvroSchema() = #externalMacro(module: "AvroMacros", type: "GenerateAvroSchema")

@attached(member, names: arbitrary)
public macro AvroEnum(namespace: String? = nil, doc: String? = nil) =
	#externalMacro(module: "AvroMacros", type: "GenerateAvroEnum")

@attached(member, names: arbitrary)
public macro AvroUnion() = #externalMacro(module: "AvroMacros", type: "GenerateAvroUnion")

@attached(peer)
public macro LogicalType(_ name: AvroSchemaDefinition.LogicalType) =
	#externalMacro(module: "AvroMacros", type: "LogicalTypeAttribute")
