//
//  ExpectedStatesRemovedByActionEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

public struct ExpectedStatesRemovedByActionEvaluator: SingleActionEvaluator {

	private let state: GameState
	private let possibleStates: [PossibleState]

	private let inquiryEvaluator: ExpectedStatesRemovedByInquiryEvaluator
	private let informingEvaluator: ExpectedStatesRemovedByInformingEvaluator

	public init(state: GameState, possibleStates: [PossibleState]) {
		self.state = state
		self.possibleStates = possibleStates
		self.inquiryEvaluator = ExpectedStatesRemovedByInquiryEvaluator(state: state, possibleStates: possibleStates)
		self.informingEvaluator = ExpectedStatesRemovedByInformingEvaluator(state: state, possibleStates: possibleStates)
	}

	public func evaluate(action: PotentialAction) -> Int? {
		switch action {
		case .inquiry(let inquiry):
			return inquiryEvaluator.evaluate(inquiry: inquiry)
		case .informing(let informing):
			return informingEvaluator.evaluate(informing: informing)
		}
	}

}
