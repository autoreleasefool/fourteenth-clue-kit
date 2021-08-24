//
//  PossibleStateEliminationSolver.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Algorithms
import Foundation

public protocol PossibleStateEliminationSolverDelegate: MysterySolverDelegate {
	func solver(
		_ solver: MysterySolver,
		didGeneratePossibleStates possibleStates: [PossibleState],
		forState state: GameState
	)
}

/// Searches for a solution to a mystery by eliminating contradictory states, and examining which possible
/// states remain for probable solutions.
public class PossibleStateEliminationSolver: MysterySolver {

	public weak var delegate: MysterySolverDelegate?

	private var tasks: [UUID: State] = [:]
	private var cancelledTasks: Set<UUID> = []
	private var lastGameState: GameState?

	private let maxConcurrentTasks: Int

	public init(maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
	}

	public func cancelSolving(state: GameState) {
		cancelledTasks.insert(state.id)
		delegate?.solver(self, didEncounterError: .cancelled, forState: state)
	}

	public func progressSolving(state: GameState) -> Double? {
		tasks[state.id]?.progress
	}

	public func solve(state: GameState) {
		let currentState = State(gameState: state, maxConcurrentTasks: maxConcurrentTasks)
		tasks[state.id] = currentState

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning state elimination")

		if let lastGameState = lastGameState,
			 let task = tasks[lastGameState.id],
			 task.isComplete,
			 lastGameState.isEarlierState(of: currentState.gameState) {
			currentState.possibleStates = task.possibleStates
		}

		lastGameState = currentState.gameState

		if currentState.possibleStates.isEmpty {
			currentState.gameState.allPossibleStates(state: currentState) {
				self.isSolving(state: currentState.gameState)
			}
		}

		reporter.reportStep(message: "Finished generating states: \(currentState.possibleStates.count)")
		currentState.progress = 0.5

		resolveMyAccusations(in: currentState)
		reporter.reportStep(message: "Finished resolving my accusations: \(currentState.possibleStates.count)")
		currentState.progress = 0.6

		resolveOpponentAccusations(in: currentState)
		reporter.reportStep(message: "Finished resolving opponent accusations: \(currentState.possibleStates.count)")
		currentState.progress = 0.7

		resolveInquisitionsInIsolation(in: currentState)
		reporter.reportStep(message: "Finished resolving inquisitions in isolation: \(currentState.possibleStates.count)")
		currentState.progress = 0.8

		resolveInquisitionsInCombination(in: currentState)
		reporter.reportStep(message: "Finished resolving inquisitions in combination: \(currentState.possibleStates.count)")
		currentState.progress = 0.9

		let solutions = currentState.possibleStates.toSolutions()
		guard isSolving(state: currentState.gameState) else {
			reporter.reportStep(message: "No longer solving state '\(currentState.gameState.id)'")
			return
		}

		reporter.reportStep(message: "Finished generating \(currentState.possibleStates.count) possible states.")
		currentState.progress = 1.0
		delegate?.solver(self, didReturnSolutions: solutions.sorted().reversed(), forState: currentState.gameState)
		(delegate as? PossibleStateEliminationSolverDelegate)?
			.solver(self, didGeneratePossibleStates: currentState.possibleStates, forState: currentState.gameState)
		currentState.isComplete = true
	}

	private func isSolving(state: GameState) -> Bool {
		!cancelledTasks.contains(state.id)
	}

	private func resolveMyAccusations(in state: State) {
		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			// Filter out clues from opponents
			.filter { $0.element.player == myPlayer.id }
			// Only look at accusations
			.compactMap { offset, action -> (Int, Accusation)? in
				guard case let .accuse(accusation) = action else { return nil }
				return (offset, accusation)
			}
			.forEach { _, accusation in
				// Remove state if the solution is identical to any accusation already made
				state.possibleStates.removeAll { $0.solution.cards == accusation.cards }
			}
	}

	private func resolveOpponentAccusations(in state: State) {
		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			// Filter out clues from me
			.filter { $0.element.player != myPlayer.id }
			// Only look at accusations
			.compactMap { offset, action -> (Int, Accusation)? in
				guard case let .accuse(accusation) = action else { return nil }
				return (offset, accusation)
			}
			.forEach { _, accusation in
				guard isSolving(state: state.gameState) else { return }

				// Remove state if any cards in the accusation appear in the solution (opponents cannot guess cards they can see)
				state.possibleStates.removeAll { !$0.solution.cards.isDisjoint(with: accusation.cards) }
			}
	}

	private func resolveInquisitionsInCombination(in state: State) {
		guard isSolving(state: state.gameState) else { return }
	}

}

// MARK: - Isolation rules

extension PossibleStateEliminationSolver {

	private func resolveInquisitionsInIsolation(in state: State) {
		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			// Filter out clues from me
			.filter { $0.element.player != myPlayer.id }
			// Only look at inquisitions (ignore accusations)
			.compactMap { offset, action -> (Int, Inquisition)? in
				guard case let .inquire(inquisition) = action else { return nil }
				return (offset, inquisition)
			}
			.forEach { _, inquisition in
				guard isSolving(state: state.gameState) else { return }

				applyRuleIfPlayerSeesNoneOfCategory(state, inquisition)
				applyRuleIfPlayerSeesSomeOfCategory(state, inquisition)
				applyRuleIfPlayerSeesAllOfCategory(state, inquisition)
				applyRuleIfPlayerAsksAboutCategory(state, inquisition)
			}
	}

	private func applyRuleIfPlayerSeesNoneOfCategory(_ state: State, _ inquisition: Inquisition) {
		guard inquisition.count == 0 else { return }

		let categoryCards = inquisition.cards.intersection(state.gameState.cards)

		// Remove states where any other player has said category in their mystery (would be visible to answering player)
		state.possibleStates.removeAll {
			$0.players
				.filter { $0.id != inquisition.answeringPlayer }
				.contains { !$0.mystery.cards.isDisjoint(with: categoryCards) }

		}

		// Remove states where answering player has said category in their hidden (would be visible to them)
		state.possibleStates.removeAll {
			$0.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { !$0.hidden.cards.isDisjoint(with: categoryCards) }
		}
	}

	private func applyRuleIfPlayerSeesSomeOfCategory(_ state: State, _ inquisition: Inquisition) {
		let categoryCards = inquisition.cards.intersection(state.gameState.cards)
		let stateCardsMatchingCategory = state.gameState.cards.matching(filter: inquisition.filter)

		guard inquisition.count > 0 && inquisition.count < stateCardsMatchingCategory.count else { return }

		// Remove states where cards answering player can see does not equal their stated answer
		state.possibleStates.removeAll { possibleState in
			possibleState.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { possibleState.cardsVisible(toPlayer: $0.id).intersection(categoryCards).count != inquisition.count }
		}
	}

	private func applyRuleIfPlayerSeesAllOfCategory(_ state: State, _ inquisition: Inquisition) {
		let categoryCards = inquisition.cards.intersection(state.gameState.cards)
		let stateCardsMatchingCategory = state.gameState.cards.matching(filter: inquisition.filter)

		guard inquisition.count == stateCardsMatchingCategory.count else { return }

		// Remove states where any other player has said category in their hidden (would not be visible to answering player)
		state.possibleStates.removeAll {
			$0.players
				.filter { $0.id != inquisition.answeringPlayer }
				.contains { !$0.hidden.cards.isDisjoint(with: categoryCards) }
		}

		// Remove states where answering player has said category in their mystery (would not be visible to them)
		state.possibleStates.removeAll {
			$0.players
				.filter { $0.id == inquisition.answeringPlayer }
				.contains { !$0.mystery.cards.isDisjoint(with: categoryCards) }
		}

		// Remove states where secret informants contain category (would not be visible to answering player)
		state.possibleStates.removeAll {
			!$0.informants.isDisjoint(with: categoryCards)
		}
	}

	private func applyRuleIfPlayerAsksAboutCategory(_ state: State, _ inquisition: Inquisition) {
		let categoryCards = inquisition.cards.intersection(state.gameState.cards)

		// Remove states where player can see all of the cards in the category
		state.possibleStates.removeAll { possibleState in
			possibleState.players
				.filter { $0.id == inquisition.askingPlayer }
				.contains { categoryCards.isSubset(of: possibleState.cardsVisible(toPlayer: $0.id)) }
		}
	}

}

// MARK: - State

extension PossibleStateEliminationSolver {

	class State {
		let gameState: GameState
		let maxConcurrentTasks: Int

		var isComplete: Bool = false
		var progress: Double = 0

		var possibleStates: [PossibleState] = []

		init(gameState: GameState, maxConcurrentTasks: Int) {
			self.gameState = gameState
			self.maxConcurrentTasks = maxConcurrentTasks
		}

	}

}

// MARK: - GameState

extension GameState {

	func allPossibleStates(state: PossibleStateEliminationSolver.State, isRunning: @escaping () -> Bool) {
		let myPlayer = players.first!
		let possibleSolutions = allPossibleSolutions()

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.PossibleState.Result.\(self.id)")
		let dispatchQueue = DispatchQueue(
			label: "ca.josephroque.FourteenthClueKit.PossibleState.Dispatch.\(self.id)",
			attributes: .concurrent
		)

		let chunked = possibleSolutions.chunks(ofCount: state.maxConcurrentTasks)
		let group = DispatchGroup()

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
						state.possibleStates.append(contentsOf: states)
					}
				}

				group.leave()
			}
		}

		group.wait()
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
