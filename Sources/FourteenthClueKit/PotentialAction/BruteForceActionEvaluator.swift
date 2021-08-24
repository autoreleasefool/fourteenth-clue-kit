//
//  BruteForceActionEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

import Foundation

public class BruteForceActionEvaluator: PotentialActionEvaluator {

	public weak var delegate: PotentialActionEvaluatorDelegate?

	public var isStreamingActions: Bool = false

	private let evaluator: SingleActionEvaluator.Type

	private var tasks: [UUID: State] = [:]
	private var cancelledTasks: Set<UUID> = []

	private let maxConcurrentTasks: Int

	public init(evaluator: SingleActionEvaluator.Type, maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
		self.evaluator = evaluator
	}

	public func cancelEvaluating(state: GameState) {
		cancelledTasks.insert(state.id)
		delegate?.evaluator(self, didEncounterError: .cancelled, forState: state)
	}

	public func progressEvaluating(state: GameState) -> Double? {
		guard let task = tasks[state.id] else { return nil }

		let totalActions = task.totalActionsToEvaluate
		let actionsEvaluated = task.actionsEvaluated

		guard totalActions > 0 else { return 0 }
		return Double(actionsEvaluated) / Double(totalActions)
	}

	public func findOptimalAction(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		let state = State(baseState: baseState, possibleStates: possibleStates)
		tasks[baseState.id] = state

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning action evaluation")

		let actions = baseState.allPossibleActions()
		let chunked = actions.chunks(ofCount: maxConcurrentTasks)
		reporter.reportStep(message: "Finished generating actions")

		let evaluator = self.evaluator.init(state: state.baseState, possibleStates: state.possibleStates)

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Result.\(baseState.id)")
		let dispatchQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Dispatch.\(baseState.id)", attributes: .concurrent)

		let group = DispatchGroup()
		chunked.forEach { actions in
			group.enter()
			dispatchQueue.async {
				actions.forEach { action in
					guard self.isEvaluating(id: baseState.id) else { return }
					guard !baseState.actionHasBeenTaken(action: action) else { return }

					let ranking = evaluator.evaluate(action: action)

					resultQueue.sync {
						guard let ranking = ranking else {
							return
						}

						if ranking > state.highestRanking {
							state.highestRanking = ranking
							state.bestActions = [action]

							if self.isStreamingActions {
								self.delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: baseState)
							}
						} else if ranking == state.highestRanking {
							state.bestActions.append(action)

							if self.isStreamingActions {
								self.delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: baseState)
							}
						}
					}
				}

				group.leave()
			}
		}

		group.wait()
		guard isEvaluating(id: baseState.id) else {
			reporter.reportStep(message: "No longer finding optimal inquiry for state '\(baseState.id)'")
			return
		}

		reporter.reportStep(message: "Finished evaluating \(state.bestActions.count) actions, with ranking of \(state.highestRanking)")
		delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: state.baseState)
		delegate?.evaluator(self, didEncounterError: .completed, forState: state.baseState)
	}

	private func isEvaluating(id: UUID) -> Bool {
		!cancelledTasks.contains(id)
	}

}

extension BruteForceActionEvaluator {

	class State {

		let baseState: GameState
		let possibleStates: [PossibleState]

		var bestActions: [PotentialAction] = []
		var highestRanking = 0

		var totalActionsToEvaluate: Int = 0
		var actionsEvaluated = 0

		init(baseState: GameState, possibleStates: [PossibleState]) {
			self.baseState = baseState
			self.possibleStates = possibleStates
		}

	}

}

// MARK: - GameState

extension GameState {

	func allPossibleActions() -> [PotentialAction] {
		(
			allPossibleInquiries().map { .inquiry($0) } +
			allPossibleInformings().map { .informing($0) }
		).shuffled()
	}

	func allPossibleInformings() -> [Informing] {
		self.secretInformants.map { Informing(informant: $0.name) }
	}

}
