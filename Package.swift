// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SVPullToRefresh",
	platforms: [
		.iOS(.v14)
	],
	products: [
		.library(
			name: "SVPullToRefresh",
			targets: [
				"SVPullToRefresh"
			]
		)
	],
	targets: [
		.target(
			name: "SVPullToRefresh",
            dependencies: [],
			path: "SVPullToRefresh",
			publicHeadersPath: "."
		)
	]
)
