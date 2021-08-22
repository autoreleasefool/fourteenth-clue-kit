//
//  InquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

public enum InquiryEvaluatorError: Error {
	case completed
	case cancelled
}

public protocol InquiryEvaluatorDelegate: AnyObject {
	func evaluator(_ evaluator: InquiryEvaluator, didFindOptimalInquiries inquiries: [Inquiry], forState state: GameState)
	func evaluator(_ evaluator: InquiryEvaluator, didEncounterError error: InquiryEvaluatorError, forState state: GameState)
}

public protocol InquiryEvaluator {
	var delegate: InquiryEvaluatorDelegate? { get set }

	/// When `true`, delegate is called constantly as best inquiries are evaluated and updated
	var isStreamingInquiries: Bool { get set }

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

public protocol SingleInquiryEvaluator {
	init(state: GameState, possibleStates: [PossibleState])

	/// Evaluates a single `Inquiry` and returns a ranking
	func evaluate(inquiry: Inquiry) -> Int?
}
