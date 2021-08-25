//
//  SolutionEliminationSolver.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Foundation

/// Searches for a solution to a mystery by eliminating contradictory solutions
public class SolutionEliminationSolver: MysterySolver {

	public weak var delegate: MysterySolverDelegate?

	private var tasks: [UUID: State] = [:]
	private var cancelledTasks: Set<UUID> = []

	private let maxConcurrentTasks: Int

	public init(maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
	}

	public func cancelSolving(gameState: GameState) {
		cancelledTasks.insert(gameState.id)
		delegate?.solver(self, didEncounterError: .cancelled, forState: gameState)
		tasks[gameState.id] = nil
	}

	public func progressSolving(gameState: GameState) -> Double? {
		tasks[gameState.id]?.progress
	}

	public func solve(gameState: GameState) {
		let state = State(gameState: gameState)
		tasks[state.gameState.id] = state
		state.progress = 0.2

		removeImpossibleSolutions(in: state)
		state.progress = 0.4
		resolveMyAccusations(in: state)
		state.progress = 0.6
		resolveOpponentAccusations(in: state)
		state.progress = 0.8
		resolveInquisitionsInIsolation(in: state)
		state.progress = 0.9
		resolveInquisitionsInCombination(in: state)
		state.progress = 1.0

		guard isSolving(gameState: gameState) else { return }
		delegate?.solver(
			self,
			didReturnSolutions: state.solutions.sorted().reversed(),
			forState: state.gameState
		)
		tasks[state.gameState.id] = nil
	}

	private func isSolving(gameState: GameState) -> Bool {
		!cancelledTasks.contains(gameState.id)
	}

	private func removeImpossibleSolutions(in state: State) {
		guard isSolving(gameState: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!
		let others =  state.gameState.players.dropFirst()

		// Remove solutions with cards that other players have
		let allOthersCards = others.flatMap { $0.cards }
		state.solutions.removeAll { !$0.cards.isDisjoint(with: allOthersCards) }

		// Remove solutions with cards in my private cards
		state.solutions.removeAll { !$0.cards.isDisjoint(with: myPlayer.hidden.cards) }

		// Remove solutions with secret informants
		state.solutions.removeAll { !$0.cards.isDisjoint(with: state.gameState.secretInformants.compactMap { $0.card })}

		// Remove any solutions that do not match confirmed cards
		myPlayer.mystery.cards.forEach { confirmedCard in
			state.solutions.removeAll { !$0.cards.contains(confirmedCard) }
		}
	}

	private func resolveMyAccusations(in state: State) {
		guard isSolving(gameState: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			.filter { $0.element.player == myPlayer.id }
			.compactMap { offset, action -> (Int, Accusation)? in
				guard case let .accuse(accusation) = action else { return nil }
				return (offset, accusation)
			}
			.forEach { _, accusation in
				// Remove solution if the accusation was already made (and was incorrect)
				state.solutions.removeAll { $0.cards == accusation.cards }
			}
	}

	private func resolveOpponentAccusations(in state: State) {
		guard isSolving(gameState: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			.filter { $0.element.player != myPlayer.id }
			.compactMap { offset, action -> (Int, Accusation)? in
				guard case let .accuse(accusation) = action else { return nil }
				return (offset, accusation)
			}
			.forEach { _, accusation in
				// Remove solution if any cards are in the accusation (opponents cannot guess cards they can see)
				state.solutions.removeAll { !$0.cards.isDisjoint(with: accusation.cards) }
			}
	}

	private func resolveInquisitionsInIsolation(in state: State) {
		guard isSolving(gameState: state.gameState) else { return }

		let myPlayer = state.gameState.players.first!

		state.gameState.actions
			.enumerated()
			.filter { $0.element.player != myPlayer.id }
			.compactMap { offset, action -> (Int, Inquisition)? in
				guard case let .inquire(inquisition) = action else { return nil }
				return (offset, inquisition)
			}
			.forEach { _, inquisition in
				guard inquisition.count > 0 else {
					state.solutions.removeAll { !$0.cards.isDisjoint(with: inquisition.cards) }
					return
				}

//				let mysteryCardsVisibleToMe = state.mysteryCardsVisibleToMe(excludingPlayer: inquisition.player)
			}
	}

	private func resolveInquisitionsInCombination(in state: State) {
		guard isSolving(gameState: state.gameState) else { return }
	}

}

// MARK: - State

extension SolutionEliminationSolver {

	class State {
		let gameState: GameState

		var solutions: [Solution]
		var progress: Double = 0

		init(gameState: GameState) {
			self.gameState = gameState
			self.solutions = gameState.allPossibleSolutions()
		}

	}

}

// MARK: - GameState

extension GameState {

	func allPossibleSolutions() -> [Solution] {
		let myPlayer = players.first!
		let cardsForSolutions = unallocatedCards

		let possiblePeople = myPlayer.mystery.person != nil
			? [myPlayer.mystery.person!]
			: cardsForSolutions.people

		let possibleLocations = myPlayer.mystery.location != nil
			? [myPlayer.mystery.location!]
			: cardsForSolutions.locations

		let possibleWeapons = myPlayer.mystery.weapon != nil
			? [myPlayer.mystery.weapon!]
			: cardsForSolutions.weapons

		return possiblePeople.flatMap { person in
			possibleLocations.flatMap { location in
				possibleWeapons.map { weapon in
					Solution(
						person: person,
						location: location,
						weapon: weapon,
						probability: 0
					)
				}
			}
		}
	}

}
