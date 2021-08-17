//
//  Solution.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// A solution to a game. Equivalent to a `MysteryCardSet`, but with no optional properties
public struct Solution: Equatable, Comparable, Identifiable, Hashable {

	/// The person of the solution
	public let person: Card
	/// The location of the solution
	public let location: Card
	/// The weapon of the solution
	public let weapon: Card

	/// The probability the solution is the correct one
	public let probability: Double

	public var id: String {
		"\(person)/\(location)/\(weapon)"
	}

	/// Cards in the solution
	public var cards: Set<Card> {
		[person, location, weapon]
	}

	public init(person: Card, location: Card, weapon: Card, probability: Double = 0) {
		assert(person.isPerson)
		assert(location.isLocation)
		assert(weapon.isWeapon)
		assert((0...1.0).contains(probability))
		self.person = person
		self.location = location
		self.weapon = weapon
		self.probability = probability
	}

	public init(_ mystery: PossibleMysterySet, probability: Double = 0) {
		self.init(
			person: mystery.person,
			location: mystery.location,
			weapon: mystery.weapon,
			probability: probability
		)
	}

	public static func < (lhs: Solution, rhs: Solution) -> Bool {
		(lhs.probability, lhs.person, lhs.location, lhs.weapon) <
			(rhs.probability, rhs.person, rhs.location, rhs.weapon)
	}

}
