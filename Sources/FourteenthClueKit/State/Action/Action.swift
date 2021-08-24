//
//  Action.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// An action taken in the game
public protocol Actionable {

	/// Unique ID
	var id: UUID { get }
	/// ID of the player who took the action
	var player: String { get }
	/// Number of the action
	var ordinal: Int { get }

	/// Description of the Action in the given state
	func description(withState state: GameState) -> String

}

public enum Action: Actionable, Identifiable, Equatable {

	case accuse(Accusation)
	case inquire(Inquisition)
	case examine(Examination)

	public var id: UUID {
		switch self {
		case .accuse(let accusation):
			return accusation.id
		case .inquire(let inquisition):
			return inquisition.id
		case .examine(let examination):
			return examination.id
		}
	}

	public var player: String {
		switch self {
		case .accuse(let accusation):
			return accusation.player
		case .inquire(let inquisition):
			return inquisition.player
		case .examine(let examination):
			return examination.player
		}
	}

	public var ordinal: Int {
		switch self {
		case .accuse(let accusation):
			return accusation.ordinal
		case .inquire(let inquisition):
			return inquisition.ordinal
		case .examine(let examination):
			return examination.ordinal
		}
	}

	public func description(withState state: GameState) -> String {
		switch self {
		case .accuse(let accusation):
			return accusation.description(withState: state)
		case .inquire(let inquisition):
			return inquisition.description(withState: state)
		case .examine(let examination):
			return examination.description(withState: state)
		}
	}

}
