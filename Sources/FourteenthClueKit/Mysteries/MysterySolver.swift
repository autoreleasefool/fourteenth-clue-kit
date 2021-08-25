//
//  MysterySolver.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

public enum MysterySolverError: Error {
	case cancelled
}

public protocol MysterySolverDelegate: AnyObject {
	func solver(_ solver: MysterySolver, didReturnSolutions solutions: [Solution], forState: GameState)
	func solver(_ solver: MysterySolver, didEncounterError error: MysterySolverError, forState: GameState)
}

public protocol MysterySolver {
	var delegate: MysterySolverDelegate? { get set }

	/// Start solving a given state.
	/// - Parameter gameState: the base game state
	func solve(gameState: GameState)
	/// Indicate the work being done to solve `gameState` should be cancelled
	func cancelSolving(gameState: GameState)
	/// Value from 0 to 1 on how close to a solution the solver is for `gameState`. Nil if there's no work in progress
	func progressSolving(gameState: GameState) -> Double?

}
