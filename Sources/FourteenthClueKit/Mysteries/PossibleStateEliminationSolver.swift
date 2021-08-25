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
	private var finishedResults: [UUID: FinishedResult] = [:]
	private var lastCompletedEvaluation: (gameState: GameState, possibleStates: [PossibleState]?)?

	private let maxConcurrentTasks: Int

	public init(maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
	}

	public func cancelSolving(gameState: GameState) {
		tasks[gameState.id] = nil
		delegate?.solver(self, didEncounterError: .cancelled, forState: gameState)
	}

	public func progressSolving(gameState: GameState) -> Double? {
		if let finishedResult = finishedResults[gameState.id], finishedResult.didComplete {
			return 1
		}

		return tasks[gameState.id]?.progress
	}

	public func solve(gameState: GameState) {
		let reporter = StepReporter(owner: self)
		let state = State(gameState: gameState, reporter: reporter, maxConcurrentTasks: maxConcurrentTasks)
		state.reporter.reportStep(message: "Beginning state elimination for state \(state.gameState.id)")
		tasks[gameState.id] = state

		defer {
			// Clean up the task once it's finished
			finishedResults[state.gameState.id] = FinishedResult(state: state)
			tasks[state.gameState.id] = nil

			if state.isComplete {
				lastCompletedEvaluation = (state.gameState, state.possibleStates)
			} else {
				lastCompletedEvaluation = nil
			}
		}

		if let lastCompletedEvaluation = lastCompletedEvaluation,
			 let lastPossibleStates = lastCompletedEvaluation.possibleStates,
			 lastCompletedEvaluation.gameState.isEarlierState(of: state.gameState) {
			state.possibleStates = lastPossibleStates
		}

		lastCompletedEvaluation = (state.gameState, nil)

		if state.possibleStates.isEmpty {
			state.gameState.allPossibleStates(maxConcurrentTasks: state.maxConcurrentTasks) {
				self.isSolving(state: state.gameState)
			} completionHandler: {
				state.possibleStates = $0
			}
		}

		state.reporter.reportStep(message: "Finished generating \(state.possibleStates.count) states")
		state.progress = 0.5

		resolveMyAccusations(in: state)
		state.progress = 0.6

		resolveOpponentAccusations(in: state)
		state.progress = 0.7

		resolveInquisitionsInIsolation(in: state)
		state.progress = 0.8

		let solutions = state.possibleStates.toSolutions()
		guard isSolving(state: state.gameState) else {
			state.reporter.reportStep(message: "No longer solving state '\(state.gameState.id)'")
			state.isComplete = false
			return
		}

		state.reporter.reportStep(message: "Finished generating \(state.possibleStates.count) possible states.")
		state.solutions = solutions.sorted().reversed()
		delegate?.solver(self, didReturnSolutions: state.solutions, forState: state.gameState)
		(delegate as? PossibleStateEliminationSolverDelegate)?
			.solver(self, didGeneratePossibleStates: state.possibleStates, forState: state.gameState)
		state.isComplete = true
	}

	private func isSolving(state: GameState) -> Bool {
		tasks[state.id] != nil
	}

	private func resolveMyAccusations(in state: State) {
		defer {
			state.reporter.reportStep(
				message: "Finished resolving my accusations: \(state.possibleStates.count) states remain"
			)
		}

		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions.enumerated()
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
		defer {
			state.reporter.reportStep(
				message: "Finished resolving opponent accusations: \(state.possibleStates.count) states remain"
			)
		}

		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions.enumerated()
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

}

// MARK: - Isolation rules

extension PossibleStateEliminationSolver {

	private func resolveInquisitionsInIsolation(in state: State) {
		defer {
			state.reporter.reportStep(
				message: "Finished resolving inquisitions in isolation: \(state.possibleStates.count) states remain"
			)
		}

		guard isSolving(state: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions.enumerated()
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
		let reporter: StepReporter
		let maxConcurrentTasks: Int

		var isComplete: Bool = false {
			didSet {
				if isComplete {
					progress = 1.0
				}
			}
		}
		var progress: Double = 0

		var possibleStates: [PossibleState] = []
		var solutions: [Solution] = []

		init(gameState: GameState, reporter: StepReporter, maxConcurrentTasks: Int) {
			self.gameState = gameState
			self.reporter = reporter
			self.maxConcurrentTasks = maxConcurrentTasks
		}

	}

}

extension PossibleStateEliminationSolver {

	struct FinishedResult {

		let solutions: [Solution]
		let didComplete: Bool

		init(state: State) {
			self.solutions = state.solutions
			self.didComplete = state.isComplete
		}

	}

}
