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

	private var tasks: [UUID: State] = [:]
	private var cancelledTasks: Set<UUID> = []

	private let maxConcurrentTasks: Int

	public init(maxConcurrentTasks: Int = 1) {
		assert(maxConcurrentTasks >= 1)
		self.maxConcurrentTasks = maxConcurrentTasks
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

		let resultQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Result.\(baseState.id)")
		let dispatchQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Dispatch.\(baseState.id)", attributes: .concurrent)

		let group = DispatchGroup()
		chunked.forEach { inquiries in
			group.enter()
			dispatchQueue.async {
				inquiries.forEach { inquiry in
					guard self.isEvaluating(id: baseState.id) else { return }
					guard !baseState.playerHasBeenAsked(inquiry: inquiry) else { return }

					let cardsInCategory = inquiry.filter.cards
						.intersection(baseState.cards)

					let totalStatesMatchingInquiry = (1...cardsInCategory.count).map { numberOfCardsSeen in
						possibleStates.filter {
							let cardsInCategoryVisibleToPlayer = $0.cardsVisible(toPlayer: inquiry.player).intersection(cardsInCategory)
							return cardsInCategoryVisibleToPlayer.count == numberOfCardsSeen
						}.count
					}

					let totalStatesRemoved = totalStatesMatchingInquiry.reduce(0, +)

					guard totalStatesRemoved > 0 else { return }

					let statesRemovedByAnswer = totalStatesMatchingInquiry.map { totalStatesRemoved - $0 }
					let probabilityOfAnswer = totalStatesMatchingInquiry.map { Double($0) / Double(totalStatesRemoved) }
					let expectedStatesRemoved = zip(statesRemovedByAnswer, probabilityOfAnswer)
						.map { Double($0) * $1 }
						.reduce(0, +)

					let intExpectedStatesRemoved = Int(expectedStatesRemoved)

					resultQueue.sync {
						if intExpectedStatesRemoved > state.highestExpectedStatesRemoved {
							state.highestExpectedStatesRemoved = intExpectedStatesRemoved
							state.bestInquiries = [inquiry]
						} else if intExpectedStatesRemoved == state.highestExpectedStatesRemoved {
							state.bestInquiries.append(inquiry)
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

		reporter.reportStep(message: "Finished evaluating \(state.bestInquiries.count) inquiries, with expected value of \(state.highestExpectedStatesRemoved)")
		delegate?.evaluator(self, didFindOptimalInquiries: state.bestInquiries.sorted(), forState: baseState)
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
		var highestExpectedStatesRemoved = 0

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
