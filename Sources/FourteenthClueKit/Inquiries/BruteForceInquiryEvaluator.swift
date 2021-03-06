//
//  BruteForceInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Algorithms
import Foundation

public class BruteForceInquiryEvaluator: InquiryEvaluator {

	public weak var delegate: InquiryEvaluatorDelegate?

	public var isStreamingInquiries: Bool = false

	private let evaluator: SingleInquiryEvaluator.Type

	private var tasks: [UUID: State] = [:]
	private var finishedResults: [UUID: Evaluation] = [:]

	private let maxConcurrentTasks: Int

	public init(evaluator: SingleInquiryEvaluator.Type, maxConcurrentTasks: Int = 1) {
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

		let totalInquiries = task.totalInquiriesToEvaluate
		let inquiriesEvaluated = task.inquiriesEvaluated

		guard totalInquiries > 0 else { return 0 }
		return Double(inquiriesEvaluated) / Double(totalInquiries)
	}

	public func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		let state = State(baseState: baseState, possibleStates: possibleStates)
		tasks[baseState.id] = state

		defer {
			// Clean up the task once it's finished
			finishedResults[baseState.id] = Evaluation(state: state)
			tasks[baseState.id] = nil
		}

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning inquiry evaluation")

		let inquiries = baseState.allPossibleInquiries().shuffled()
		let chunked = inquiries.chunks(ofCount: maxConcurrentTasks)
		reporter.reportStep(message: "Finished generating inquiries")

		let evaluator = self.evaluator.init(state: state.baseState, possibleStates: state.possibleStates)

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Result.\(baseState.id)")
		let dispatchQueue = DispatchQueue(
			label: "ca.josephroque.FourteenthClueKit.BruteForce.Dispatch.\(baseState.id)",
			attributes: .concurrent
		)

		let group = DispatchGroup()
		chunked.forEach { inquiries in
			group.enter()
			dispatchQueue.async {
				inquiries.forEach { inquiry in
					guard self.isEvaluating(stateId: baseState.id) else { return }

					guard !baseState.playerHasBeenAsked(inquiry: inquiry) else { return }

					guard let ranking = evaluator.evaluate(inquiry: inquiry) else { return }

					self.updateOptimalInquiries(withNewInquiry: inquiry, ranking: ranking, state: state, onQueue: resultQueue)
				}

				group.leave()
			}
		}

		group.wait()
		guard isEvaluating(stateId: baseState.id) else {
			reporter.reportStep(message: "No longer finding optimal inquiry for state '\(baseState.id)'")
			state.didFinishEvaluation = false
			return
		}

		reporter.reportStep(
			message: "Finished evaluating \(state.bestInquiries.count) inquiries, with ranking of \(state.highestRanking)"
		)
		state.didFinishEvaluation = true
		delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: state.baseState)
		delegate?.evaluator(self, didEncounterError: .completed, forState: state.baseState)
	}

	private func isEvaluating(stateId: UUID) -> Bool {
		tasks[stateId] != nil
	}

	private func updateOptimalInquiries(
		withNewInquiry inquiry: Inquiry,
		ranking: Int,
		state: State,
		onQueue: DispatchQueue
	) {
		onQueue.sync {
			if ranking > state.highestRanking {
				state.highestRanking = ranking
				state.bestInquiries = [inquiry]

				if self.isStreamingInquiries {
					self.delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: state.baseState)
				}
			} else if ranking == state.highestRanking {
				state.bestInquiries.append(inquiry)

				if self.isStreamingInquiries {
					self.delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: state.baseState)
				}
			}
		}
	}
}

extension BruteForceInquiryEvaluator {

	class State {

		let baseState: GameState
		let possibleStates: [PossibleState]

		var bestInquiries: [Inquiry] = []
		var highestRanking = 0

		var totalInquiriesToEvaluate: Int = 0
		var inquiriesEvaluated = 0

		var didFinishEvaluation = false

		init(baseState: GameState, possibleStates: [PossibleState]) {
			self.baseState = baseState
			self.possibleStates = possibleStates
		}

	}

}

extension BruteForceInquiryEvaluator {

	struct Evaluation {

		let bestInquiries: [Inquiry]
		let highestRanking: Int
		let didFinishEvaluation: Bool

		init(state: State) {
			self.bestInquiries = state.bestInquiries
			self.highestRanking = state.highestRanking
			self.didFinishEvaluation = state.didFinishEvaluation
		}

	}

}

// MARK: - GameState

extension GameState {

	func allPossibleInquiries() -> [Inquiry] {
		let playersAndFilters = product(
			players.dropFirst().map { $0.id },
			allInquiryCategories()
		)

		if numberOfPlayers == 2 {
			return product(
				playersAndFilters,
				Card.HiddenCardPosition.allCases
			).map { playerAndFilter, position in
				Inquiry(player: playerAndFilter.0, filter: playerAndFilter.1, includingCardOnSide: position)
			}
		} else {
			return playersAndFilters.map {
				Inquiry(player: $0, filter: $1, includingCardOnSide: nil)
			}
		}
	}

	private func allInquiryCategories() -> [Card.Filter] {
		[
			.category(.person(.man)),
			.category(.person(.woman)),
			.category(.location(.indoors)),
			.category(.location(.outdoors)),
			.category(.weapon(.melee)),
			.category(.weapon(.ranged)),
		] + cards.map({ $0.color }).uniqued().map { .color($0) }
	}

}
