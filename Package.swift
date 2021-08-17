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
	dependencies: [],
	targets: [
		.target(
			name: "FourteenthClueKit",
			dependencies: []
		),
		.testTarget(
			name: "FourteenthClueKitTests",
			dependencies: ["FourteenthClueKit"]
		),
	]
)
