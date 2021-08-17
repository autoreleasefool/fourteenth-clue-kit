//
//  Examination.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

public struct Examination: Action, Equatable {

	public let id = UUID()
	public let player: String
	public let ordinal: Int

	/// ID of the informant see
	public let informant: String

	public init(ordinal: Int, player: String, informant: String) {
		self.ordinal = ordinal
		self.player = player
		self.informant = informant
	}

	public func description(withState state: GameState) -> String {
		guard let player = state.players.first(where: { $0.id == self.player }),
					let informant = state.secretInformants.first(where: { $0.name == self.informant })
		else {
			return "Invalid examination"
		}

		var informantInfo: String = ""
		if let card = informant.card {
			informantInfo = " and saw \(card.name)"
		}

		return "[\(ordinal)] \(player.name) looked at informant \(self.informant)" + informantInfo
	}

}
