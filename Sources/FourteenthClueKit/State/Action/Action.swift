//
//  Action.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// An action taken in the game
public protocol Action {

	/// Unique ID
	var id: UUID { get }
	/// ID of the player who took the action
	var player: String { get }
	/// Number of the action
	var ordinal: Int { get }

	/// Description of the Action in the given state
	func description(withState state: GameState) -> String
	/// `true` if two `Action`s are equal
	func isEqual(to other: Action) -> Bool

}

extension Action where Self: Equatable {

	public func isEqual(to other: Action) -> Bool {
		guard let other = other as? Self else { return false }
		return self == other
	}

}

// MARK: - AnyAction

public struct AnyAction: Action, Identifiable {

	public let wrappedValue: Action

	public var id: UUID { wrappedValue.id }
	public var player: String { wrappedValue.player }
	public var ordinal: Int { wrappedValue.ordinal }

	public init(_ action: Action) {
		assert((action as? AnyAction) == nil)
		self.wrappedValue = action
	}

	public func description(withState state: GameState) -> String {
		wrappedValue.description(withState: state)
	}

}

extension AnyAction: Equatable {

	public static func == (lhs: AnyAction, rhs: AnyAction) -> Bool {
		return lhs.wrappedValue.isEqual(to: rhs.wrappedValue)
	}

}
