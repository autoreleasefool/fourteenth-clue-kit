//
//  File.swift
//  File
//
//  Created by Joseph Roque on 2021-08-16.
//

import XCTest
@testable import FourteenthClueKit

final class GameStateTests: XCTestCase {

	func testNumberOfPlayers() {
		let state = GameState(playerCount: 3)
		XCTAssertEqual(state.numberOfPlayers, 3)
	}
	
}
