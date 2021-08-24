//
//  Clue.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// A clue given by a player
public protocol Clue: Actionable {

	/// Cards included in the clue
	var cards: Set<Card> { get }

}
