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
	private var cancelledTasks: Set<UUID> = []

	private let maxConcurrentTasks: Int

	public init(evaluator: SingleInquiryEvaluator.Type, maxConcurrentTasks: Int = 1) {
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

		let totalInquiries = task.totalInquiriesToEvaluate
		let inquiriesEvaluated = task.inquiriesEvaluated

		guard totalInquiries > 0 else { return 0 }
		return Double(inquiriesEvaluated) / Double(totalInquiries)
	}

	public func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		let state = State(baseState: baseState, possibleStates: possibleStates)
		tasks[baseState.id] = state

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning inquiry evaluation")

		let inquiries = baseState.allPossibleInquiries()
		let chunked = inquiries.chunks(ofCount: maxConcurrentTasks)
		reporter.reportStep(message: "Finished generating inquiries")

		let evaluator = self.evaluator.init(state: state.baseState, possibleStates: state.possibleStates)

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Result.\(baseState.id)")
		let dispatchQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Dispatch.\(baseState.id)", attributes: .concurrent)

		let group = DispatchGroup()
		chunked.forEach { inquiries in
			group.enter()
			dispatchQueue.async {
				inquiries.forEach { inquiry in
					guard self.isEvaluating(id: baseState.id) else { return }
					guard !baseState.playerHasBeenAsked(inquiry: inquiry) else { return }

					let ranking = evaluator.evaluate(inquiry: inquiry)

					resultQueue.sync {
						guard let ranking = ranking else {
							return
						}

						if ranking > state.highestRanking {
							state.highestRanking = ranking
							state.bestInquiries = [inquiry]

							if self.isStreamingInquiries {
								self.delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: baseState)
							}
						} else if ranking == state.highestRanking {
							state.bestInquiries.append(inquiry)

							if self.isStreamingInquiries {
								self.delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: baseState)
							}
						}
					}

					group.leave()
				}
			}
		}

		group.wait()
		guard isEvaluating(id: baseState.id) else {
			reporter.reportStep(message: "No longer finding optimal inquiry for state '\(baseState.id)'")
			return
		}

		reporter.reportStep(message: "Finished evaluating \(state.bestInquiries.count) inquiries, with ranking of \(state.highestRanking)")
		delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: state.baseState)
		delegate?.evaluator(self, didEncounterError: .completed, forState: state.baseState)
	}

	private func isEvaluating(id: UUID) -> Bool {
		!cancelledTasks.contains(id)
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

		init(baseState: GameState, possibleStates: [PossibleState]) {
			self.baseState = baseState
			self.possibleStates = possibleStates
		}

	}

}

// MARK: - GameState

extension GameState {

	func allPossibleInquiries() -> [Inquiry] {
		product(
			players.dropFirst().map { $0.id },
			allInquiryCategories()
		).map(Inquiry.init)
	}

	private func allInquiryCategories() -> [Card.Filter] {
		[
			.category(.person(.man)),
			.category(.person(.woman)),
			.category(.location(.indoors)),
			.category(.location(.outdoors)),
			.category(.weapon(.melee)),
			.category(.weapon(.ranged)),
		] + cards.map({$0.color}).uniqued().map { .color($0) }
	}

}
