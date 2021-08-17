//
//  SecretInformant.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// A secret informant in the game
public struct SecretInformant: Hashable {

	/// The name of the informant
	public let name: String
	/// The card of the informant
	public let card: Card?

	public init(name: String, card: Card?) {
		self.name = name
		self.card = card
	}

	// MARK: Mutations

	/// Replace the card in the informant
	/// - Parameter card: new card
	func with(card: Card?) -> SecretInformant {
		.init(name: name, card: card)
	}

}
