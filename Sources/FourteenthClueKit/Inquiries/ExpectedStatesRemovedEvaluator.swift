//
//  ExpectedStatesRemovedEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public struct ExpectedStatesRemovedEvaluator: SingleInquiryEvaluator {

	private let state: GameState
	private let possibleStates: [PossibleState]

	public init(state: GameState, possibleStates: [PossibleState]) {
		self.state = state
		self.possibleStates = possibleStates
	}

	public func evaluate(inquiry: Inquiry) -> Int? {
		let cardsInCategory = inquiry.filter.cards
			.intersection(state.cards)

		let numberOfStatesMatchingAnswer = (1...cardsInCategory.count).map { numberOfCardsSeen in
			possibleStates.filter {
				let cardsInCategoryVisibleToPlayer = $0.cardsVisible(toPlayer: inquiry.player).intersection(cardsInCategory)
				return cardsInCategoryVisibleToPlayer.count == numberOfCardsSeen
			}.count
		}

		let numberOfStatesRemovedByAnswer = numberOfStatesMatchingAnswer.map { possibleStates.count - $0 }

		let probabilityOfAnswer = numberOfStatesMatchingAnswer.map { Double($0) / Double(possibleStates.count) }

		let expectedStatesRemovedByInquiry = zip(numberOfStatesRemovedByAnswer, probabilityOfAnswer)
			.map { Double($0) * $1 }
			.reduce(0, +)

		return Int(expectedStatesRemovedByInquiry)
	}

}
