//
//  HiddenCardSet.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// A player's hidden cards, visible only to themselves
public struct HiddenCardSet: Hashable {

	/// The first of the player's hidden cards
	public let left: Card?
	/// The second of the player's hidden cards
	public let right: Card?

	public init(left: Card? = nil, right: Card? = nil) {
		self.left = left
		self.right = right
	}

	// MARK: Mutations

	/// Replace the left card in this set
	/// /// - Parameter onLeft: card to insert on the left side
	public func withCard(onLeft left: Card?) -> HiddenCardSet {
		.init(left: left, right: right)
	}

	/// Replace the right card in this set
	/// - Parameter onRight: card to insert on the right side
	public func withCard(onRight right: Card?) -> HiddenCardSet {
		.init(left: left, right: right)
	}

	// MARK: Properties

	/// All of the cards in the set
	public var cards: Set<Card> {
		Set([left, right].compactMap { $0 })
	}

	public func cardOn(side: Card.HiddenCardPosition) -> Card? {
		switch side {
		case .left: return left
		case .right: return right
		}
	}

}
