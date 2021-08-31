//
//  PossibleHiddenSet.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// A player's possible hidden cards. Equivalent to `HiddenCardSet`, but with non-optional properties
public struct PossibleHiddenSet {
	/// The left hidden card
	public let left: Card
	/// The right hidden card
	public let right: Card

	public init(left: Card, right: Card) {
		assert(left != right)
		self.left = left
		self.right = right
	}

	public init(_ hidden: HiddenCardSet) {
		self.init(left: hidden.left!, right: hidden.right!)
	}

	public init<C: Collection>(_ cards: C) where C.Element == Card {
		self.left = cards.first!
		self.right = cards.dropFirst().first!
	}

	/// Cards in the hidden set
	public var cards: Set<Card> {
		[left, right]
	}

	public func cardOn(side: Card.HiddenCardPosition) -> Card {
		switch side {
		case .left: return left
		case .right: return right
		}
	}

}
