//
//  Inquisition.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// An Inquisition that a player has made, asking another player
public struct Inquisition: Clue, Equatable {

	public let id = UUID()
	public let ordinal: Int

	/// ID of the player that questioned the player
	public let askingPlayer: String
	/// ID of the player that answered the question
	public let answeringPlayer: String
	/// Filter the inquisition was made about
	public let filter: Card.Filter
	/// Number of cards matching the filter seen by the answering player
	public let count: Int
	/// In two player games, you must specify if the player should include their left or right hidden card
	public let includingCardOnSide: Card.HiddenCardPosition?

	/// Cards in the accusation
	public var cards: Set<Card> {
		Card.allCardsMatching(filter: filter)
	}

	public var player: String {
		answeringPlayer
	}

	public init(
		ordinal: Int,
		askingPlayer: String,
		answeringPlayer: String,
		filter: Card.Filter,
		includingCardOnSide: Card.HiddenCardPosition?,
		count: Int
	) {
		self.ordinal = ordinal
		self.askingPlayer = askingPlayer
		self.answeringPlayer = answeringPlayer
		self.filter = filter
		self.includingCardOnSide = includingCardOnSide
		self.count = count
	}

	public func description(withState state: GameState) -> String {
		let askingPlayer = state.players.first(where: { $0.id == self.askingPlayer })!
		let answeringPlayer = state.players.first(where: { $0.id == self.answeringPlayer })!
		let includingCard = includingCardOnSide == nil ? "" : ", including their \(includingCardOnSide!) card"
		return """
			[\(ordinal)] \(askingPlayer.name) asks \(answeringPlayer.name), \
			they see \(count) \(filter.description)\(includingCard)
			"""
	}

}
