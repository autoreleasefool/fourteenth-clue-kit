//
//  PossibleMysterySet.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// A player's possible mystery. Equivalent to `MysteryCardSet`, but with non-optional properties
public struct PossibleMysterySet {
	/// The person in the mystery
	public let person: Card
	/// The location in the mystery
	public let location: Card
	/// The weapon in the mystery
	public let weapon: Card

	public init(person: Card, location: Card, weapon: Card) {
		assert(person.isPerson)
		assert(location.isLocation)
		assert(weapon.isWeapon)
		self.person = person
		self.location = location
		self.weapon = weapon
	}

	public init(_ solution: Solution) {
		self.init(person: solution.person, location: solution.location, weapon: solution.weapon)
	}

	public init(_ mystery: MysteryCardSet) {
		self.init(person: mystery.person!, location: mystery.location!, weapon: mystery.weapon!)
	}

	/// Cards in the mystery
	public var cards: Set<Card> {
		[person, location, weapon]
	}
}
