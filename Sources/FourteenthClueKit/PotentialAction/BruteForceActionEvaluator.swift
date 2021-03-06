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
	private var finishedResults: [UUID: Evaluation] = [:]

	private let maxConcurrentTasks: Int

	public init(evaluator: SingleActionEvaluator.Type, maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
		self.evaluator = evaluator
	}

	public func cancelEvaluating(state: GameState) {
		tasks[state.id] = nil
		delegate?.evaluator(self, didEncounterError: .cancelled, forState: state)
	}

	public func progressEvaluating(state: GameState) -> Double? {
		if let evaluation = finishedResults[state.id], evaluation.didFinishEvaluation {
			return 1
		}

		guard let task = tasks[state.id] else { return nil }

		let totalActions = task.totalActionsToEvaluate
		let actionsEvaluated = task.actionsEvaluated

		guard totalActions > 0 else { return 0 }
		return Double(actionsEvaluated) / Double(totalActions)
	}

	public func findOptimalAction(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		let state = State(baseState: baseState, possibleStates: possibleStates)
		tasks[baseState.id] = state

		defer {
			// Clean up the task once it's finished
			finishedResults[baseState.id] = Evaluation(state: state)
			tasks[baseState.id] = nil
		}

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning action evaluation")

		let actions = baseState.allPossibleActions()
		let chunked = actions.chunks(ofCount: maxConcurrentTasks)
		reporter.reportStep(message: "Finished generating actions")

		let evaluator = self.evaluator.init(state: state.baseState, possibleStates: state.possibleStates)

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Result.\(baseState.id)")
		let dispatchQueue = DispatchQueue(
			label: "ca.josephroque.FourteenthClueKit.BruteForce.Dispatch.\(baseState.id)",
			attributes: .concurrent
		)

		let group = DispatchGroup()
		chunked.forEach { actions in
			group.enter()
			dispatchQueue.async {
				actions.forEach { action in
					guard self.isEvaluating(stateId: baseState.id) else { return }

					guard !baseState.actionHasBeenTaken(action: action) else { return }

					guard let ranking = evaluator.evaluate(action: action) else { return }

					self.updateOptimalActions(withNewAction: action, ranking: ranking, state: state, onQueue: resultQueue)
				}

				group.leave()
			}
		}

		group.wait()
		guard isEvaluating(stateId: baseState.id) else {
			reporter.reportStep(message: "No longer finding optimal action for state '\(baseState.id)'")
			state.didFinishEvaluation = false
			return
		}

		reporter.reportStep(
			message: "Finished evaluating \(state.bestActions.count) actions, with ranking of \(state.highestRanking)"
		)
		state.didFinishEvaluation = true
		delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: state.baseState)
		delegate?.evaluator(self, didEncounterError: .completed, forState: state.baseState)
	}

	private func isEvaluating(stateId: UUID) -> Bool {
		tasks[stateId] != nil
	}

	private func updateOptimalActions(
		withNewAction action: PotentialAction,
		ranking: Int,
		state: State,
		onQueue: DispatchQueue
	) {
		onQueue.sync {
			if ranking > state.highestRanking {
				state.highestRanking = ranking
				state.bestActions = [action]

				if self.isStreamingActions {
					self.delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: state.baseState)
				}
			} else if ranking == state.highestRanking {
				state.bestActions.append(action)

				if self.isStreamingActions {
					self.delegate?.evaluator(self, didFindOptimalActions: state.bestActions.sorted(), forState: state.baseState)
				}
			}
		}
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

		var didFinishEvaluation = false

		init(baseState: GameState, possibleStates: [PossibleState]) {
			self.baseState = baseState
			self.possibleStates = possibleStates
		}

	}

}

extension BruteForceActionEvaluator {

	struct Evaluation {

		let bestActions: [PotentialAction]
		let highestRanking: Int
		let didFinishEvaluation: Bool

		init(state: State) {
			self.bestActions = state.bestActions
			self.highestRanking = state.highestRanking
			self.didFinishEvaluation = state.didFinishEvaluation
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
