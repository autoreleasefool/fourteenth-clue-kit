//
//  MysteryCardSet.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// A player's mystery they are trying to solve
public struct MysteryCardSet: Hashable {

	/// The person in the mystery
	public let person: Card?
	/// The location in the mystery
	public let location: Card?
	/// The weapon in the mystery
	public let weapon: Card?

	public init(person: Card? = nil, location: Card? = nil, weapon: Card? = nil) {
		assert(person?.isPerson != false)
		assert(location?.isLocation != false)
		assert(weapon?.isWeapon != false)
		self.person = person
		self.location = location
		self.weapon = weapon
	}

	// MARK: Mutations

	/// Replace the person in the mystery
	/// - Parameter person: the new person
	public func with(person newPerson: Card?) -> MysteryCardSet {
		.init(person: newPerson, location: location, weapon: weapon)
	}

	/// Replace the location in the mystery
	/// - Parameter location: the new location
	public func with(location newLocation: Card?) -> MysteryCardSet {
		.init(person: person, location: newLocation, weapon: weapon)
	}

	/// Replace the weapon in the mystery
	/// - Parameter weapon: the new weapon
	public func with(weapon newWeapon: Card?) -> MysteryCardSet {
		.init(person: person, location: location, weapon: newWeapon)
	}

	// MARK: Properties

	/// `true` if all the cards are set
	public var isComplete: Bool {
		person != nil && location != nil && weapon != nil
	}

	/// All of the cards in the mystery
	public var cards: Set<Card> {
		Set([person, location, weapon].compactMap { $0 })
	}
}
