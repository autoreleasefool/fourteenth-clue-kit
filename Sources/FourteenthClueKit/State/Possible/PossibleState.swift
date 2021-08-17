//
//  PossibleState.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// A possible state which encompasses the entire game
public struct PossibleState {

	/// The players and their cards in the possible state
	public let players: [PossiblePlayer]
	/// The informants in the possible state
	public let informants: Set<Card>

	/// The first player's solution
	public var solution: Solution {
		Solution(players.first!.mystery)
	}

	/// Returns the set of cards visible to a given player
	public func cardsVisible(toPlayer targetPlayer: String) -> Set<Card> {
		players.reduce(into: Set<Card>()) { cards, player in
			cards.formUnion(
				targetPlayer == player.id
					? player.hidden.cards
					: player.mystery.cards
			)
		}
	}
}
