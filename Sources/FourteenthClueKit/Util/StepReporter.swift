//
//  StepReporter.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-17.
//

import Foundation

class StepReporter {
	let ownerName: String
	let startTime: DispatchTime
	var steps = 0

	init(owner: Any) {
		let name = String(describing: owner)
		if let periodIndex = name.firstIndex(of: ".") {
			self.ownerName = String(name[name.index(after: periodIndex)...])
		} else {
			self.ownerName = name
		}
		startTime = DispatchTime.now()
	}

	func reportStep(message: String) {
		steps += 1

		let currentTime = DispatchTime.now()
		let nanoTime = currentTime.uptimeNanoseconds - startTime.uptimeNanoseconds
		let timeInterval = Double(nanoTime) / 1_000_000_000

		guard Configuration.isLoggingEnabled else { return }
		print("[\(ownerName)][\(String(format: "%.2f", timeInterval))] \(steps). \(message)")
	}
}
