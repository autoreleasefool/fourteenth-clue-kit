// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "FourteenthClueKit",
	products: [
		.library(
			name: "FourteenthClueKit",
			targets: ["FourteenthClueKit"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-algorithms", from: "0.0.1"),
	],
	targets: [
		.target(
			name: "FourteenthClueKit",
			dependencies: [
				.product(name: "Algorithms", package: "swift-algorithms"),
			]
		),
		.testTarget(
			name: "FourteenthClueKitTests",
			dependencies: ["FourteenthClueKit"]
		),
	]
)
