//
//  Clue.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// A clue given by a player
public protocol Clue: Action {

	/// Cards included in the clue
	var cards: Set<Card> { get }

}

// MARK: - AnyClue

public struct AnyClue: Clue {

	public let wrappedValue: Clue

	public var ordinal: Int { wrappedValue.ordinal }
	public var id: UUID { wrappedValue.id }
	public var player: String { wrappedValue.player }
	public var cards: Set<Card> { wrappedValue.cards }

	public init(_ clue: Clue) {
		self.wrappedValue = clue
	}

	public func description(withState state: GameState) -> String {
		wrappedValue.description(withState: state)
	}

}

extension AnyClue: Equatable {

	public static func == (lhs: AnyClue, rhs: AnyClue) -> Bool {
		return lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
	}

}
