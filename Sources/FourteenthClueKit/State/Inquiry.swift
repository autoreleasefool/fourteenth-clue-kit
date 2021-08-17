//
//  Inquiry.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// Inquiry to make
public struct Inquiry: Equatable {

	/// Player who will be asked
	public let player: String
	/// Card type that will be asked about
	public let filter: Card.Filter

}

extension Inquiry: Comparable {

	public static func < (lhs: Inquiry, rhs: Inquiry) -> Bool {
		(lhs.player, lhs.filter) < (rhs.player, rhs.filter)
	}

}
