//
//  SolutionEliminationSolver.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

/// Searches for a solution to a mystery by eliminating contradictory solutions
public class SolutionEliminationSolver: MysterySolver {

	private var currentState: GameState?

	public weak var delegate: MysterySolverDelegate?

	public init() {}

	public func cancel() {
		currentState = nil
		delegate?.solver(self, didEncounterError: .cancelled)
	}

	public func solve(state: GameState) {
		currentState = state

		var solutions = state.allPossibleSolutions()

		removeImpossibleSolutions(in: state, &solutions)
		resolveMyAccusations(in: state, &solutions)
		resolveOpponentAccusations(in: state, &solutions)
		resolveInquisitionsInIsolation(in: state, &solutions)
		resolveInquisitionsInCombination(in: state, &solutions)

		guard isRunning(withState: state) else { return }
		delegate?.solver(self, didReturnSolutions: solutions)
	}

	private func isRunning(withState state: GameState) -> Bool {
		currentState?.id == state.id
	}

	private func removeImpossibleSolutions(in state: GameState, _ solutions: inout [Solution]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!
		let others = state.players.dropFirst()

		// Remove solutions with cards that other players have
		let allOthersCards = others.flatMap { $0.cards }
		solutions.removeAll { !$0.cards.isDisjoint(with: allOthersCards) }

		// Remove solutions with cards in my private cards
		solutions.removeAll { !$0.cards.isDisjoint(with: me.hidden.cards) }

		// Remove solutions with secret informants
		solutions.removeAll { !$0.cards.isDisjoint(with: state.secretInformants.compactMap { $0.card })}

		// Remove any solutions that do not match confirmed cards
		me.mystery.cards.forEach { confirmedCard in
			solutions.removeAll { !$0.cards.contains(confirmedCard) }
		}
	}

	private func resolveMyAccusations(in state: GameState, _ solutions: inout [Solution]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			.filter { $0.element.player == me.id }
			.compactMap { offset, action -> (Int, Accusation)? in
				guard let accusation = action.wrappedValue as? Accusation else { return nil }
				return (offset, accusation)
			}
			.forEach { offset, accusation in
				// Remove solution if the accusation was already made (and was incorrect)
				solutions.removeAll { $0.cards == accusation.cards }
			}
	}

	private func resolveOpponentAccusations(in state: GameState,_ solutions: inout [Solution]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			.filter { $0.element.player != me.id }
			.compactMap { offset, action -> (Int, Accusation)? in
				guard let accusation = action.wrappedValue as? Accusation else { return nil }
				return (offset, accusation)
			}
			.forEach { offset, accusation in
				// Remove solution if any cards are in the accusation (opponents cannot guess cards they can see)
				solutions.removeAll { !$0.cards.isDisjoint(with: accusation.cards) }
			}
	}

	private func resolveInquisitionsInIsolation(in state: GameState, _ solutions: inout [Solution]) {
		guard isRunning(withState: state) else { return }

		let me = state.players.first!

		state.actions
			.enumerated()
			.filter { $0.element.player != me.id }
			.compactMap { offset, action -> (Int, Inquisition)? in
				guard let inquisition = action.wrappedValue as? Inquisition else { return nil }
				return (offset, inquisition)
			}
			.forEach { offset, inquisition in
				guard inquisition.count > 0 else {
					solutions.removeAll { !$0.cards.isDisjoint(with: inquisition.cards) }
					return
				}

//				let mysteryCardsVisibleToMe = state.mysteryCardsVisibleToMe(excludingPlayer: inquisition.player)
			}
	}

	private func resolveInquisitionsInCombination(in state: GameState, _ solutions: inout [Solution]) {
		guard isRunning(withState: state) else { return }
	}

}

// MARK: - GameState

extension GameState {

	func allPossibleSolutions() -> [Solution] {
		let me = players.first!
		let cardsForSolutions = unallocatedCards

		let possiblePeople = me.mystery.person != nil
			? [me.mystery.person!]
			: cardsForSolutions.people

		let possibleLocations = me.mystery.location != nil
			? [me.mystery.location!]
			: cardsForSolutions.locations

		let possibleWeapons = me.mystery.weapon != nil
			? [me.mystery.weapon!]
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
