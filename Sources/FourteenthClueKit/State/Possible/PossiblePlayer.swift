//
//  PossiblePlayer.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// A player's possible hidden cards and mystery. Equivalent to `Player`, but with non-optional properties
public struct PossiblePlayer {
	/// Unique ID
	public let id: String
	/// The player's mystery
	public let mystery: PossibleMysterySet
	/// The player's hidden cards
	public let hidden: PossibleHiddenSet
}
