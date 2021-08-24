//
//  ExpectedStatesRemovedByActionEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

extension ExpectedStates {

	public struct RemovedByActionEvaluator: SingleActionEvaluator {

		private let state: GameState
		private let possibleStates: [PossibleState]

		private let inquiryEvaluator: ExpectedStates.RemovedByInquiryEvaluator
		private let informingEvaluator: ExpectedStates.RemovedByInformingEvaluator

		public init(state: GameState, possibleStates: [PossibleState]) {
			self.state = state
			self.possibleStates = possibleStates
			self.inquiryEvaluator = ExpectedStates.RemovedByInquiryEvaluator(state: state, possibleStates: possibleStates)
			self.informingEvaluator = ExpectedStates.RemovedByInformingEvaluator(state: state, possibleStates: possibleStates)
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

}
