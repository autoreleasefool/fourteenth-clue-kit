//
//  ExpectedSolutionsRemovedByInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public struct ExpectedSolutions {

	private init() {}

}

extension ExpectedSolutions {

	public struct RemovedByInquiryEvaluator: SingleInquiryEvaluator {

		private let state: GameState
		private let possibleStates: [PossibleState]
		private let solutions: [Solution]

		public init(state: GameState, possibleStates: [PossibleState]) {
			self.state = state
			self.possibleStates = possibleStates
			self.solutions = possibleStates.toSolutions()
		}

		public func evaluate(inquiry: Inquiry) -> Int? {
			let cardsInCategory = inquiry.filter.cards
				.intersection(state.cards)

			let numberOfStatesAndSolutionsMatchingAnswer = (1...cardsInCategory.count).map { numberOfCardsSeen -> (Int, Int) in
				let statesMatching = possibleStates.filter {
					let cardsInCategoryVisibleToPlayer = $0.cardsVisible(
						toPlayer: inquiry.player,
						includingCardOnSide: inquiry.includingCardOnSide
					).intersection(cardsInCategory)
					return cardsInCategoryVisibleToPlayer.count == numberOfCardsSeen
				}

				return (statesMatching.count, statesMatching.toSolutions().count)
			}

			let numberOfStatesMatchingAnswer = numberOfStatesAndSolutionsMatchingAnswer.map { $0.0 }
			let numberOfSolutionsMatchingAnswer = numberOfStatesAndSolutionsMatchingAnswer.map { $0.1 }

			let numberOfSolutionsRemovedByAnswer = numberOfSolutionsMatchingAnswer.map { solutions.count - $0 }

			let probabilityOfAnswer = numberOfStatesMatchingAnswer.map { Double($0) / Double(possibleStates.count) }

			let expectedSolutionsRemovedByInquiry = zip(numberOfSolutionsRemovedByAnswer, probabilityOfAnswer)
				.map { Double($0) * $1 }
				.reduce(0, +)

			return Int(expectedSolutionsRemovedByInquiry)
		}

	}

}
