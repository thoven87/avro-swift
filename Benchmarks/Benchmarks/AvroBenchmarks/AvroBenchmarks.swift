import Avro
import Benchmark
import Foundation

let benchmarks: @Sendable () -> Void = {

	// Complex record benchmark (nested structures, multiple types)
	Benchmark(
		"Complex Record - Encoding",
		configuration: .init(
			metrics: [.wallClock])
	) { benchmark in
		let value = ComplexFixture.instance
		let encoder = AvroEncoder(schema: ComplexFixture.Def.avroSchema)
		for _ in benchmark.scaledIterations {
			_ = try encoder.encode(value)
		}
	}

	Benchmark(
		"Complex Record - Decoding",
		configuration: .init(
			metrics: [.wallClock])
	) { benchmark in
		let value = ComplexFixture.serialized
		let decoder = AvroDecoder(schema: ComplexFixture.Def.avroSchema)
		for _ in benchmark.scaledIterations {
			_ = try decoder.decode(ComplexFixture.Def.self, from: value)
		}
	}
}
