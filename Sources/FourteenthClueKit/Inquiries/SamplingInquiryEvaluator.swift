//
//  SamplingInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public class SamplingInquiryEvaluator: InquiryEvaluator {

	public weak var delegate: InquiryEvaluatorDelegate? {
		get {
			baseEvaluator.delegate
		}
		set {
			baseEvaluator.delegate = newValue
		}
	}

	public var isStreamingInquiries: Bool {
		get {
			baseEvaluator.isStreamingInquiries
		}
		set {
			baseEvaluator.isStreamingInquiries = newValue
		}
	}

	var sampleRate: Double
	private var baseEvaluator: InquiryEvaluator

	public init(
		baseEvaluator: InquiryEvaluator,
		sampleRate: Double = 0.1
	) {
		self.baseEvaluator = baseEvaluator
		self.sampleRate = sampleRate
	}

	public func cancelEvaluating(state: GameState) {
		baseEvaluator.cancelEvaluating(state: state)
	}

	public func progressEvaluating(state: GameState) -> Double? {
		baseEvaluator.progressEvaluating(state: state)
	}

	public func findOptimalInquiry(in baseState: GameState, withPossibleStates possibleStates: [PossibleState]) {
		let sampledStates = possibleStates.randomSample(count: Int(Double(possibleStates.count) * sampleRate))
		baseEvaluator.findOptimalInquiry(in: baseState, withPossibleStates: sampledStates)
	}
}
