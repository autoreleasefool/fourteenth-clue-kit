//
//  PossibleState.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Foundation

/// A possible state which encompasses the entire game
public struct PossibleState {

	/// The players and their cards in the possible state
	public let players: [PossiblePlayer]
	/// The informants in the possible state
	public let informants: Set<Card>

	/// The first player's solution
	public var solution: Solution {
		Solution(players.first!.mystery)
	}

	/// Returns the set of cards visible to a given player
	public func cardsVisible(toPlayer targetPlayer: String) -> Set<Card> {
		players.reduce(into: Set<Card>()) { cards, player in
			cards.formUnion(
				targetPlayer == player.id
					? player.hidden.cards
					: player.mystery.cards
			)
		}
	}
}

// MARK: - GameState

extension GameState {

	func allPossibleStates(
		maxConcurrentTasks: Int,
		isRunning: @escaping () -> Bool,
		completionHandler: ([PossibleState]) -> Void
	) {
		let myPlayer = players.first!
		let possibleSolutions = allPossibleSolutions()

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.PossibleState.Result.\(self.id)")
		let dispatchQueue = DispatchQueue(
			label: "ca.josephroque.FourteenthClueKit.PossibleState.Dispatch.\(self.id)",
			attributes: .concurrent
		)

		let chunked = possibleSolutions.chunks(ofCount: maxConcurrentTasks)
		let group = DispatchGroup()
		var possibleStates: [PossibleState] = []

		chunked.forEach { solutions in
			group.enter()
			dispatchQueue.async {
				for solution in solutions {
					let mySolution = PossiblePlayer(
						id: myPlayer.id,
						mystery: PossibleMysterySet(solution),
						hidden: PossibleHiddenSet(myPlayer.hidden)
					)

					let remainingCards = initialUnknownCards.subtracting(solution.cards)
					let cardPairs = Array(remainingCards.combinations(ofCount: 2))
						.map { Set($0) }

					let states = GameState.generatePossibleStates(
						withBaseState: self,
						players: [mySolution],
						cardPairs: cardPairs,
						isRunning: isRunning
					)

					resultQueue.sync {
						possibleStates.append(contentsOf: states)
					}
				}

				group.leave()
			}
		}

		group.wait()
		completionHandler(possibleStates)
	}

	private static func generatePossibleStates(
		withBaseState state: GameState,
		players: [PossiblePlayer],
		cardPairs: [Set<Card>],
		isRunning: () -> Bool
	) -> [PossibleState] {
		guard isRunning() else { return [] }

		var possibleStates: [PossibleState] = []
		guard players.count < state.numberOfPlayers else {
			possibleStates.append(PossibleState(
				players: players,
				informants: Set(cardPairs.flatMap { $0 })
			))
			return possibleStates
		}

		let nextPlayerIndex = players.count
		cardPairs.forEach { pair in
			let nextPlayer = PossiblePlayer(
				id: state.players[nextPlayerIndex].id,
				mystery: PossibleMysterySet(state.players[nextPlayerIndex].mystery),
				hidden: PossibleHiddenSet(pair)
			)

			possibleStates.append(contentsOf: GameState.generatePossibleStates(
				withBaseState: state,
				players: players + [nextPlayer],
				cardPairs: cardPairs.filter { $0.isDisjoint(with: pair) },
				isRunning: isRunning
			))
		}

		return possibleStates
	}

}

// MARK: - Solutions

extension Array where Element == PossibleState {

	func toSolutions() -> [Solution] {
		guard !self.isEmpty else { return [] }

		return self.reduce(into: [Solution: Int]()) { counts, possibleState in
			counts[possibleState.solution] = (counts[possibleState.solution] ?? 0) + 1
		}.map { key, value in
			Solution(
				person: key.person,
				location: key.location,
				weapon: key.weapon,
				probability: Double(value) / Double(self.count)
			)
		}
	}

}
