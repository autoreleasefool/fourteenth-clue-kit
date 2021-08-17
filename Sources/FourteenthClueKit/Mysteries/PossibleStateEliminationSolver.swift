//
//  PossibleStateEliminationSolver.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Algorithms

public protocol PossibleStateEliminationSolverDelegate: MysterySolverDelegate {
	func solver(_ solver: MysterySolver, didGeneratePossibleStates possibleStates: [PossibleState], for state: GameState)
}

/// Searches for a solution to a mystery by eliminating contradictory states, and examining which possible states remain for probable solutions.
public class PossibleStateEliminationSolver: MysterySolver {

	public weak var delegate: MysterySolverDelegate?

	private var currentState: GameState?
	private var cachedStates: [PossibleState]?

	public init() {}

	public func cancel() {
		currentState = nil
		delegate?.solver(self, didEncounterError: .cancelled)
	}

	public func solve(state: GameState) {
		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning state elimination")

		if let prevState = currentState,
			 shouldClearStateCache(prevState: prevState, nextState: state) {
			cachedStates = nil
		}

		currentState = state

		var states = cachedStates ?? state.allPossibleStates { [weak self] in
			self?.isRunning(withState: state) == true
		}
		reporter.reportStep(message: "Finished generating states")

		resolveMyAccusations(in: state, &states)
		reporter.reportStep(message: "Finished resolving my accusations")

		resolveOpponentAccusations(in: state, &states)
		reporter.reportStep(message: "Finished resolving opponent accusations")

		resolveInquisitionsInIsolation(in: state, &states)
		reporter.reportStep(message: "Finished resolving inquisitions in isolation")

		resolveInquisitionsInCombination(in: state, &states)
		reporter.reportStep(message: "Finished resolving inquisitions in combination")

		let solutions = processStatesIntoSolutions(states)
		guard isRunning(withState: state) else { return }

		reporter.reportStep(message: "Finished generating \(states.count) possible states.")
		delegate?.solver(self, didReturnSolutions: solutions.sorted())
		(delegate as? PossibleStateEliminationSolverDelegate)?.solver(self, didGeneratePossibleStates: states, for: state)
	}

	private func isRunning(withState state: GameState) -> Bool {
		currentState?.id == state.id
	}

	private func resolveMyAccusations(in state: GameState, _ possibleStates: inout [PossibleState]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			// Filter out clues from opponents
			.filter { $0.element.player == me.id }
			// Only look at accusations
			.compactMap { offset, action -> (Int, Accusation)? in
				guard let accusation = action.wrappedValue as? Accusation else { return nil }
				return (offset, accusation)
			}
			.forEach { offset, accusation in
				// Remove state if the solution is identical to any accusation already made
				possibleStates.removeAll { $0.solution.cards == accusation.cards }
			}
	}

	private func resolveOpponentAccusations(in state: GameState, _ possibleStates: inout [PossibleState]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			// Filter out clues from me
			.filter { $0.element.player != me.id }
			// Only look at accusations
			.compactMap { offset, action -> (Int, Accusation)? in
				guard let accusation = action.wrappedValue as? Accusation else { return nil }
				return (offset, accusation)
			}
			.forEach { offset, accusation in
				guard isRunning(withState: state) else { return }

				// Remove state if any cards in the accusation appear in the solution (opponents cannot guess cards they can see)
				possibleStates.removeAll { !$0.solution.cards.isDisjoint(with: accusation.cards) }
			}
	}

	private func resolveInquisitionsInCombination(in state: GameState, _ possibleStates: inout [PossibleState]) {
		guard isRunning(withState: state) else { return }
	}

	private func processStatesIntoSolutions(_ states: [PossibleState]) -> [Solution] {
		states.reduce(into: [Solution:Int]()) { counts, possibleState in
			counts[possibleState.solution] = (counts[possibleState.solution] ?? 0) + 1
		}.map { key, value in
			Solution(
				person: key.person,
				location: key.location,
				weapon: key.weapon,
				probability: Double(value) / Double(states.count)
			)
		}
	}

	private func shouldClearStateCache(prevState: GameState, nextState: GameState) -> Bool {
		!prevState.isEarlierState(of: nextState)
	}

}

// MARK: - Isolation rules

extension PossibleStateEliminationSolver {

	private func resolveInquisitionsInIsolation(in state: GameState, _ possibleStates: inout [PossibleState]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			// Filter out clues from me
			.filter { $0.element.player != me.id }
			// Only look at inquisitions (ignore accusations)
			.compactMap { offset, action -> (Int, Inquisition)? in
				guard let inquisition = action.wrappedValue as? Inquisition else { return nil }
				return (offset, inquisition)
			}
			.forEach { offset, inquisition in
				guard isRunning(withState: state) else { return }

				applyRuleIfPlayerSeesNoneOfCategory(state, inquisition, &possibleStates)
				applyRuleIfPlayerSeesSomeOfCategory(state, inquisition, &possibleStates)
				applyRuleIfPlayerSeesAllOfCategory(state, inquisition, &possibleStates)
				applyRuleIfPlayerAsksAboutCategory(state, inquisition, &possibleStates)
			}
	}

	private func applyRuleIfPlayerSeesNoneOfCategory(
		_ state: GameState,
		_ inquisition: Inquisition,
		_ possibleStates: inout [PossibleState]
	) {
		guard inquisition.count == 0 else { return }

		let categoryCards = inquisition.cards.intersection(state.cards)

		// Remove states where any other player has said category in their mystery (would be visible to answering player)
		possibleStates.removeAll {
			$0.players
				.filter { $0.id != inquisition.answeringPlayer }
				.contains { !$0.mystery.cards.isDisjoint(with: categoryCards) }

		}

		// Remove states where answering player has said category in their hidden (would be visible to them)
		possibleStates.removeAll {
			$0.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { !$0.hidden.cards.isDisjoint(with: categoryCards) }
		}
	}

	private func applyRuleIfPlayerSeesSomeOfCategory(
		_ state: GameState,
		_ inquisition: Inquisition,
		_ possibleStates: inout [PossibleState]
	) {
		let categoryCards = inquisition.cards.intersection(state.cards)
		let stateCardsMatchingCategory = state.cards.matching(filter: inquisition.filter)

		guard inquisition.count > 0 && inquisition.count < stateCardsMatchingCategory.count else { return }

		// Remove states where cards answering player can see does not equal their stated answer
		possibleStates.removeAll { possibleState in
			possibleState.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { possibleState.cardsVisible(toPlayer: $0.id).intersection(categoryCards).count != inquisition.count }
		}
	}

	private func applyRuleIfPlayerSeesAllOfCategory(
		_ state: GameState,
		_ inquisition: Inquisition,
		_ possibleStates: inout [PossibleState]
	) {
		let categoryCards = inquisition.cards.intersection(state.cards)
		let stateCardsMatchingCategory = state.cards.matching(filter: inquisition.filter)

		guard inquisition.count == stateCardsMatchingCategory.count else { return }

		// Remove states where any other player has said category in their hidden (would not be visible to answering player)
		possibleStates.removeAll {
			$0.players
				.filter { $0.id != inquisition.answeringPlayer }
				.contains { !$0.hidden.cards.isDisjoint(with: categoryCards) }
		}

		// Remove states where answering player has said category in their mystery (would not be visible to them)
		possibleStates.removeAll {
			$0.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { !$0.mystery.cards.isDisjoint(with: categoryCards) }
		}

		// Remove states where secret informants contain category (would not be visible to answering player)
		possibleStates.removeAll {
			!$0.informants.isDisjoint(with: categoryCards)
		}
	}

	private func applyRuleIfPlayerAsksAboutCategory(
		_ state: GameState,
		_ inquisition: Inquisition,
		_ possibleStates: inout [PossibleState]
	) {
		let categoryCards = inquisition.cards.intersection(state.cards)

		// Remove states where player can see all of the cards in the category
		possibleStates.removeAll { possibleState in
			possibleState.players
				.filter { $0.id == inquisition.askingPlayer }
				.contains { categoryCards.isSubset(of: possibleState.cardsVisible(toPlayer: $0.id)) }
		}
	}

}

// MARK: - GameState

extension GameState {

	func allPossibleStates(isRunning: () -> Bool) -> [PossibleState] {
		let me = players.first!
		let possibleSolutions = allPossibleSolutions()
		var possibleStates: [PossibleState] = []

		for solution in possibleSolutions {
			let mySolution = PossiblePlayer(
				id: me.id,
				mystery: PossibleMysterySet(solution),
				hidden: PossibleHiddenSet(me.hidden)
			)

			let remainingCards = initialUnknownCards.subtracting(solution.cards)
			let cardPairs = Array(remainingCards.combinations(ofCount: 2))
				.map { Set($0) }

			GameState.generatePossibleStates(
				withBaseState: self,
				players: [mySolution],
				cardPairs: cardPairs,
				into: &possibleStates,
				isRunning: isRunning
			)
		}

		return isRunning() ? possibleStates : []
	}

	private static func generatePossibleStates(
		withBaseState state: GameState,
		players: [PossiblePlayer],
		cardPairs: [Set<Card>],
		into possibleStates: inout [PossibleState],
		isRunning: () -> Bool
	) {
		guard isRunning() else { return }

		guard players.count < state.numberOfPlayers else {
			possibleStates.append(PossibleState(
				players: players,
				informants: Set(cardPairs.flatMap { $0 })
			))
			return
		}

		let nextPlayerIndex = players.count
		cardPairs.forEach { pair in
			let nextPlayer = PossiblePlayer(
				id: state.players[nextPlayerIndex].id,
				mystery: PossibleMysterySet(state.players[nextPlayerIndex].mystery),
				hidden: PossibleHiddenSet(pair)
			)

			GameState.generatePossibleStates(
				withBaseState: state,
				players: players + [nextPlayer],
				cardPairs: cardPairs.filter { $0.isDisjoint(with: pair) },
				into: &possibleStates,
				isRunning: isRunning
			)
		}
	}

}
