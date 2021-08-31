//
//  Player.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Algorithms

/// A player in the game
public struct Player: Identifiable, Hashable {

	/// The name of the player
	public let name: String
	/// The player's hidden cards, visible only to themselves
	public let hidden: HiddenCardSet
	/// The player's mystery
	public let mystery: MysteryCardSet
	/// The number of magnifying glasses the player has available to them
	public let magnifyingGlasses: Int

	public var id: String {
		name
	}

	public init(ordinal: Int) {
		self.init(
			name: "Player-\(ordinal)",
			hidden: HiddenCardSet(left: nil, right: nil),
			mystery: MysteryCardSet(person: nil, location: nil, weapon: nil),
			magnifyingGlasses: 1
		)
	}

	public init(name: String, hidden: HiddenCardSet, mystery: MysteryCardSet, magnifyingGlasses: Int) {
		assert(!name.contains(" "))
		self.name = name
		self.hidden = hidden
		self.mystery = mystery
		self.magnifyingGlasses = magnifyingGlasses
	}

	// MARK: Mutations

	/// Replace the name of the player
	/// - Parameter name: the new name
	public func with(name: String) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery, magnifyingGlasses: magnifyingGlasses)
	}

	/// Replace the left hidden card of the player
	/// - Parameter name: the new left card
	public func withHiddenCard(onLeft left: Card? = nil) -> Player {
		.init(name: name, hidden: hidden.withCard(onLeft: left), mystery: mystery, magnifyingGlasses: magnifyingGlasses)
	}

	/// Replace the right hidden card of the player
	/// - Parameter name: the new right card
	public func withHiddenCard(onRight right: Card? = nil) -> Player {
		.init(name: name, hidden: hidden.withCard(onRight: right), mystery: mystery, magnifyingGlasses: magnifyingGlasses)
	}

	/// Replace the person in the player's mystery
	/// - Parameter name: the new person
	public func withMysteryPerson(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(person: toCard), magnifyingGlasses: magnifyingGlasses)
	}

	/// Replace the location in the player's mystery
	/// - Parameter name: the new location
	public func withMysteryLocation(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(location: toCard), magnifyingGlasses: magnifyingGlasses)
	}

	/// Replace the weapon in the player's mystery
	/// - Parameter name: the new weapon
	public func withMysteryWeapon(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(weapon: toCard), magnifyingGlasses: magnifyingGlasses)
	}

	/// Add a magnifying glass to the player's total
	public func addingMagnifyingGlass() -> Player {
		.init(name: name, hidden: hidden, mystery: mystery, magnifyingGlasses: magnifyingGlasses + 1)
	}

	/// Subtract a magnifying glass from the player's total
	public func removingMagnifyingGlass() -> Player {
		.init(name: name, hidden: hidden, mystery: mystery, magnifyingGlasses: max(magnifyingGlasses - 1, 0))
	}

	// MARK: Properties

	/// All of the player's cards
	public var cards: Set<Card> {
		mystery.cards.union(hidden.cards)
	}

	/// `true` if enough information is known about they player and they are in a solveable state,
	/// based on if they are first player or not
	public func isSolveable(asFirstPlayer: Bool) -> Bool {
		if asFirstPlayer {
			return hidden.left != nil && hidden.right != nil
		} else {
			return mystery.isComplete
		}
	}

}

// MARK: Action Resolvers

extension Player {

	internal func resolvingAction(_ action: Action, in gameState: GameState) -> Player {
		guard gameState.isTrackingMagnifyingGlasses else { return self }

		switch action {
		case .accuse(let accusation):
			return resolvingAccusation(accusation)
		case .inquire(let inquisition):
			return resolvingInquisition(inquisition)
		case .examine(let examination):
			return resolvingExamination(examination, in: gameState)
		}
	}

	internal func resolvingAccusation(_ accusation: Accusation) -> Player {
		guard name == accusation.accusingPlayer else { return self }
		return .init(name: name, hidden: hidden, mystery: mystery, magnifyingGlasses: 0)
	}

	internal func resolvingInquisition(_ inquisition: Inquisition) -> Player {
		if name == inquisition.askingPlayer {
			return removingMagnifyingGlass()
		} else if name == inquisition.answeringPlayer {
			return addingMagnifyingGlass()
		}

		return self
	}

	internal func resolvingExamination(_ examination: Examination, in gameState: GameState) -> Player {
		if name == examination.player {
			return removingMagnifyingGlass()
		}

		guard self.magnifyingGlasses == 0 else { return self }

		guard let examiningPlayerIndex = gameState.players.firstIndex(where: { $0.name == examination.player }) else {
			return self
		}

		var players = gameState.players
		players.rotate(toStartAt: examiningPlayerIndex)
		if players.dropFirst().first(where: { $0.magnifyingGlasses == 0 })?.name == self.name {
			return addingMagnifyingGlass()
		} else {
			return self
		}
	}

}
