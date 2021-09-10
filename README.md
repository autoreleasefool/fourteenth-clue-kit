# FourteenthClueKit

A Swift library to help you build a solver for the board game [13 Clues](https://boardgamegeek.com/boardgame/208766/13-clues).

## Usage

## Installation

### Requirements

- Swift 5.5+
- [SwiftLint](https://github.com/realm/SwiftLint)

### Swift Package Manager

`FourteenthClueKit` supports Swift Package Manager. Until there's an official release, you can target the main branch (note that this means the API is unstable, and breaking changes can and **will** occur).

```swift
dependencies: [
	.package(url: "https://github.com/autoreleasefool/fourteenth-clue-kit.git", branch: "main"),
],
```

and add the package as a dependency for your target:

```swift
targets: [
	.target(
		name: "YourAppName",
		dependencies: [
			.product(name: "FourteenthClueKit", package: "fourteenth-clue-kit"),
		]
	),
]
```

## Contributing

1. Write your changes. If possible, test them with `swift test`.
2. Install SwiftLint for styling conformance:
   - Run `swiftlint` from the root of the repository.
   - There should be no errors or violations. If there are, please fix them before opening a PR.
3. Open a PR with your changes 👍
