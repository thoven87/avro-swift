@attached(member, names: arbitrary)
public macro Schema() = #externalMacro(module: "AvroMacros", type: "GenerateAvroSchema")

@attached(member, names: arbitrary)
public macro AvroEnum(namespace: String? = nil, doc: String? = nil) =
	#externalMacro(module: "AvroMacros", type: "GenerateAvroEnum")

@attached(peer)
public macro LogicalType(_ name: AvroSchema.LogicalType) = #externalMacro(module: "AvroMacros", type: "LogicalTypeAttribute")
