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
	func solver(_ solver: MysterySolver, didReturnSolutions solutions: [Solution])
	func solver(_ solver: MysterySolver, didEncounterError error: MysterySolverError)
}

public protocol MysterySolver {
	var delegate: MysterySolverDelegate? { get set }

	/// Value from 0 to 1 on how close to a solution the solver is for the last `state` passed. Nil if there's no work in progress
	var progress: Double? { get }

	/// Start solving a given state.
	/// - Parameter state: the base game state
	func solve(state: GameState)
	/// Indicate the work being done to solve the last `state` should be cancelled
	func cancel()

}
