//
//  PotentialActionEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public enum PotentialActionEvaluatorError: Error {
	case completed
	case cancelled
}

public protocol PotentialActionEvaluatorDelegate: AnyObject {
	func evaluator(_ evaluator: PotentialActionEvaluator, didFindOptimalActions actions: [PotentialAction], forState state: GameState)
	func evaluator(_ evaluator: PotentialActionEvaluator, didEncounterError error: PotentialActionEvaluatorError, forState state: GameState)
}

public protocol PotentialActionEvaluator {
	var delegate: PotentialActionEvaluatorDelegate? { get set }

	/// When `true`, delegate is called constantly as optimal actions are evaluated and updated
	var isStreamingActions: Bool { get set }

	/// Start finding the ideal action in a given state
	/// - Parameters
	///   - baseState: the base state action will be taken in
	///   - possibleStates: the possible states based on the base state
	func findOptimalAction(in baseState: GameState, withPossibleStates possibleStates: [PossibleState])
	/// Indicate the work being done to solve `state` should be cancelled
	func cancelEvaluating(state: GameState)
	/// Value from 0 to 1 on how close to an optimal action the evaluator is for `state`. Nil if there's no work in progress
	func progressEvaluating(state: GameState) -> Double?

}

public protocol SingleActionEvaluator {
	init(state: GameState, possibleStates: [PossibleState])

	/// Evaluates a single `PotentialAction` and returns a ranking
	func evaluate(action: PotentialAction) -> Int?
}

public protocol SingleInformingEvaluator {
	init(state: GameState, possibleStates: [PossibleState])

	/// Evaluates a single `Informing` and returns a ranking
	func evaluate(informing: Informing) -> Int?
}
