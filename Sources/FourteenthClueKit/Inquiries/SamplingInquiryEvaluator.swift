//
//  SamplingInquiryEvaluator.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public class SamplingInquiryEvaluator: InquiryEvaluator {

	public weak var delegate: InquiryEvaluatorDelegate? {
		set {
			baseEvaluator.delegate = newValue
		}
		get {
			baseEvaluator.delegate
		}
	}

	public var isStreamingInquiries: Bool {
		set {
			baseEvaluator.isStreamingInquiries = newValue
		}
		get {
			baseEvaluator.isStreamingInquiries
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