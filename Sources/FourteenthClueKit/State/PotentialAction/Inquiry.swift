//
//  Inquiry.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// Inquiry to make
public struct Inquiry {

	/// Player who will be asked
	public let player: String
	/// Card type that will be asked about
	public let filter: Card.Filter
	/// In two player games, you must specify if the player should include their left or right hidden card
	public let includingCardOnSide: Card.HiddenCardPosition?

}

extension Inquiry: Comparable {

	public static func < (lhs: Inquiry, rhs: Inquiry) -> Bool {
		return (lhs.player, lhs.filter, lhs.includingCardOnSide ?? .right) <
			(rhs.player, rhs.filter, rhs.includingCardOnSide ?? .right)
	}

}

extension Inquiry: CustomStringConvertible {

	public var description: String {
		let includingCard = includingCardOnSide == nil ? "" : ", including their \(includingCardOnSide!) card"
		return "Ask \(player) about \(filter) cards\(includingCard)"
	}

}
