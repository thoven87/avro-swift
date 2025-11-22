// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "benchmarks",
	platforms: [.macOS(.v15)],
	dependencies: [
		.package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.4.0")),
		.package(name: "avro-swift", path: "../")
	],
	targets: [
		.executableTarget(
			name: "AvroBenchmarks",
			dependencies: [
				.product(name: "Avro", package: "avro-swift"),
				.product(name: "Benchmark", package: "package-benchmark")
			],
			path: "Benchmarks/AvroBenchmarks",
			plugins: [
				.plugin(name: "BenchmarkPlugin", package: "package-benchmark")
			]
		)
	]
)
