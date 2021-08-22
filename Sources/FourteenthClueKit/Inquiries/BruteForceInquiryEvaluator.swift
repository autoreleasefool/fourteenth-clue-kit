//
//  BruteForceInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Algorithms
import Foundation

public class BruteForceInquiryEvaluator: InquiryEvaluator {

	private var state = State()

	public weak var delegate: InquiryEvaluatorDelegate?

	private let mainQueueID = UUID()
	private let mainQueueIDKey = DispatchSpecificKey<UUID>()

	private var mainQueue = DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce")
	private var maxConcurrentThreads: Int
	private var queues: [DispatchQueue]

	public var progress: Double? {
		mainQueue.sync {
			guard state.gameState != nil else { return nil }
			guard state.totalInquiriesToEvaluate > 0 else { return 0 }
			return Double(state.inquiriesEvaluated) / Double(state.totalInquiriesToEvaluate)
		}
	}

	public init(maxConcurrentThreads: Int = 1) {
		assert(maxConcurrentThreads >= 1)
		self.mainQueue.setSpecific(key: mainQueueIDKey, value: mainQueueID)
		self.maxConcurrentThreads = maxConcurrentThreads
		self.queues = (0..<maxConcurrentThreads).map {
			DispatchQueue(label: "ca.josephroque.FourteenthClueKit.BruteForce.Queue-\($0)")
		}
	}

	public func cancel() {
		mainQueue.async {
			self.state.reset()
			self.delegate?.evaluator(self, didEncounterError: .cancelled)
		}
	}

	public func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		mainQueue.async {
			self.state.reset()
			self.state.gameState = baseState
		}

		defer {
			if isRunning(withState: baseState) {
				state.inquiriesEvaluated += 1
			}
		}

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning inquiry evaluation")

		let inquiries = baseState.allPossibleInquiries()
		state.totalInquiriesToEvaluate = inquiries.count + 1
		reporter.reportStep(message: "Finished generating inquiries")

		let group = DispatchGroup()

		reporter.reportStep(message: "Starting evaluation on \(maxConcurrentThreads) queue(s).")

		let subInquiries = inquiries.chunks(ofCount: maxConcurrentThreads)
		zip(subInquiries, queues).forEach { inqueries, queue in
			group.enter()

			queue.async {
				inquiries.forEach { inquiry in
					self.mainQueue.async {
						self.state.inquiriesEvaluated += 1
					}

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

					self.mainQueue.async {
						guard self.isRunning(withState: baseState) else { return }
						if intExpectedStatesRemoved > self.state.highestExpectedStatesRemoved {
							self.state.highestExpectedStatesRemoved = intExpectedStatesRemoved
							self.state.bestInquiries = [inquiry]
						} else if intExpectedStatesRemoved == self.state.highestExpectedStatesRemoved {
							self.state.bestInquiries.append(inquiry)
						}
					}
				}

				group.leave()
			}
		}

		group.notify(queue: self.mainQueue) {
			guard self.isRunning(withState: baseState) else {
				reporter.reportStep(message: "No longer finding optimal inquiry for state '\(baseState.id)'")
				return
			}

			reporter.reportStep(message: "Finished evaluating \(self.state.bestInquiries.count) inquiries, with expected value of \(self.state.highestExpectedStatesRemoved)")
			self.delegate?.evaluator(self, didFindOptimalInquiries: self.state.bestInquiries.sorted())
		}
	}

	private func isRunning(withState state: GameState) -> Bool {
		if let id = DispatchQueue.getSpecific(key: mainQueueIDKey), id == mainQueueID {
			return self.state.gameState?.id == state.id
		} else {
			return mainQueue.sync {
				self.state.gameState?.id == state.id
			}
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

// MARK: - State

extension BruteForceInquiryEvaluator {

	struct State {
		var gameState: GameState?

		var highestExpectedStatesRemoved = 0
		var bestInquiries: [Inquiry] = []

		var totalInquiriesToEvaluate = 0
		var inquiriesEvaluated = 0

		mutating func reset() {
			self.gameState = nil
			self.highestExpectedStatesRemoved = 0
			self.bestInquiries = []
			self.totalInquiriesToEvaluate = 0
			self.inquiriesEvaluated = 0
		}
	}
}
