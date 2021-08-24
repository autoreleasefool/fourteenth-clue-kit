//
//  ExpectedStatesRemovedByInformingEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

extension ExpectedStates {

	public struct RemovedByInformingEvaluator: SingleInformingEvaluator {

		private let state: GameState
		private let possibleStates: [PossibleState]

		public init(state: GameState, possibleStates: [PossibleState]) {
			self.state = state
			self.possibleStates = possibleStates
		}

		public func evaluate(informing: Informing) -> Int? {
			guard possibleStates.count > 0 else { return nil }

			let possibleCards = state.unallocatedCards

			let numberOfStatesWithCardAsInformant = possibleCards.map { informantCard in
				possibleStates.filter { $0.informants.contains(informantCard) }.count
			}

			let numberOfStatesRemovedByCardAsInformant = numberOfStatesWithCardAsInformant.map { possibleStates.count - $0 }

			let probabilityOfCardAsInformant = numberOfStatesWithCardAsInformant
				.map { Double($0) / Double(possibleStates.count) }

			let expectedStatesRemovedByCardAsInformant = zip(
				numberOfStatesRemovedByCardAsInformant,
				probabilityOfCardAsInformant
			)
				.map { Double($0) * $1 }
				.reduce(0, +)

			return Int(expectedStatesRemovedByCardAsInformant)
		}

	}

}
