//
//  InquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

public enum InquiryEvaluatorError: Error {
	case cancelled
}

public protocol InquiryEvaluatorDelegate: AnyObject {
	func evaluator(_ evaluator: InquiryEvaluator, didFindOptimalInquiries inquiries: [Inquiry], forState state: GameState)
	func evaluator(_ evaluator: InquiryEvaluator, didEncounterError error: InquiryEvaluatorError, forState state: GameState)
}

public protocol InquiryEvaluator {
	var delegate: InquiryEvaluatorDelegate? { get set }

	/// Start finding the ideal inquiry in a given state
	/// - Parameters
	///   - baseState: the base state query will be asked in
	///   - possibleStates: the possible states based on the base state
	func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState])
	/// Indicate the work being done to solve `state` should be cancelled
	func cancelEvaluating(state: GameState)
	/// Value from 0 to 1 on how close to an inquiry the evaluator is for `state`. Nil if there's no work in progress
	func progressEvaluating(state: GameState) -> Double?

}
