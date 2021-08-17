//
//  Player.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// A player in the game
public struct Player: Identifiable, Hashable {

	/// The name of the player
	public let name: String
	/// The player's hidden cards, visible only to themselves
	public let hidden: HiddenCardSet
	/// The player's mystery
	public let mystery: MysteryCardSet

	public var id: String {
		name
	}

	public init() {
		self.name = ""
		self.hidden = HiddenCardSet(left: nil, right: nil)
		self.mystery = MysteryCardSet(person: nil, location: nil, weapon: nil)
	}

	public init(name: String, hidden: HiddenCardSet, mystery: MysteryCardSet) {
		self.name = name
		self.hidden = hidden
		self.mystery = mystery
	}

	// MARK: Mutations

	/// Replace the name of the player
	/// - Parameter name: the new name
	func with(name: String) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery)
	}

	/// Replace the left hidden card of the player
	/// - Parameter name: the new left card
	func withHiddenCard(onLeft left: Card? = nil) -> Player {
		.init(name: name, hidden: hidden.withCard(onLeft: left), mystery: mystery)
	}

	/// Replace the right hidden card of the player
	/// - Parameter name: the new right card
	func withHiddenCard(onRight right: Card? = nil) -> Player {
		.init(name: name, hidden: hidden.withCard(onRight: right), mystery: mystery)
	}

	/// Replace the person in the player's mystery
	/// - Parameter name: the new person
	func withMysteryPerson(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(person: toCard))
	}

	/// Replace the location in the player's mystery
	/// - Parameter name: the new location
	func withMysteryLocation(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(location: toCard))
	}

	/// Replace the weapon in the player's mystery
	/// - Parameter name: the new weapon
	func withMysteryWeapon(_ toCard: Card? = nil) -> Player {
		.init(name: name, hidden: hidden, mystery: mystery.with(weapon: toCard))
	}

	// MARK: Properties

	/// All of the player's cards
	var cards: Set<Card> {
		mystery.cards.union(hidden.cards)
	}

}
