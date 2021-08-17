//
//  Accusation.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// An accusation that a player has made
public struct Accusation: Clue, Equatable {

	public let id = UUID()
	public let ordinal: Int

	/// ID of the player that made the accusation
	public let accusingPlayer: String
	/// Accusation made by the player
	public let accusation: MysteryCardSet

	/// Cards in the accusation
	public var cards: Set<Card> {
		accusation.cards
	}

	public var player: String {
		accusingPlayer
	}

	public init(ordinal: Int, accusingPlayer: String, accusation: MysteryCardSet) {
		assert(accusation.isComplete)
		self.ordinal = ordinal
		self.accusingPlayer = accusingPlayer
		self.accusation = accusation
	}

	public func description(withState state: GameState) -> String {
		guard let person = accusation.person,
					let location = accusation.location,
					let weapon = accusation.weapon,
					let player = state.players.first(where: { $0.id == self.player }) else { return "Invalid accusation" }
		return "[\(ordinal)] \(player.name) has made an accusation: \(person.name), \(location.name), \(weapon.name)"
	}

}
