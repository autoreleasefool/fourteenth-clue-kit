//
//  BruteForceInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Algorithms

public class BruteForceInquiryEvaluator: InquiryEvaluator {

	private var seed: (state: GameState, possibleStates: [PossibleState])? {
		didSet {
			totalInquiriesToEvaluate = 0
			inquiriesEvaluated = 0
		}
	}
	private var totalInquiriesToEvaluate: Int = 0
	private var inquiriesEvaluated: Int = 0

	public weak var delegate: InquiryEvaluatorDelegate?

	public init() {}

	public func cancel() {
		seed = nil
		delegate?.evaluator(self, didEncounterError: .cancelled)
	}

	public var progress: Double? {
		guard seed != nil else { return nil }
		guard totalInquiriesToEvaluate > 0 else { return 0 }
		return Double(inquiriesEvaluated) / Double(totalInquiriesToEvaluate)
	}

	public func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		seed = (baseState, possibleStates)
		defer {
			if isRunning(withState: baseState) {
				self.inquiriesEvaluated += 1
			}
		}

		let reporter = StepReporter(owner: self)
		reporter.reportStep(message: "Beginning inquiry evaluation")

		let inquiries = baseState.allPossibleInquiries()
		totalInquiriesToEvaluate = inquiries.count + 1
		reporter.reportStep(message: "Finished generating inquiries")

		var highestExpectedStatesRemoved = 0
		var bestInquiries: [Inquiry] = []

		inquiries.forEach { inquiry in
			inquiriesEvaluated += 1
			guard isRunning(withState: baseState) else { return }

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

			if intExpectedStatesRemoved > highestExpectedStatesRemoved {
				highestExpectedStatesRemoved = intExpectedStatesRemoved
				bestInquiries = [inquiry]
			} else if intExpectedStatesRemoved == highestExpectedStatesRemoved {
				bestInquiries.append(inquiry)
			}
		}

		guard isRunning(withState: baseState) else {
			reporter.reportStep(message: "No longer finding optimal inquiry for state '\(baseState.id)'")
			return
		}

		reporter.reportStep(message: "Finished evaluating \(bestInquiries.count) inquiries, with expected value of \(highestExpectedStatesRemoved)")
		delegate?.evaluator(self, didFindOptimalInquiries: bestInquiries.sorted())
	}

	private func isRunning(withState state: GameState) -> Bool {
		seed?.state.id == state.id
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
