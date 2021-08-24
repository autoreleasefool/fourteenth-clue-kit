//
//  Informing.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public struct Informing {

	/// Informant to look at
	public let informant: String

}

extension Informing: Comparable {

	public static func < (lhs: Informing, rhs: Informing) -> Bool {
		lhs.informant < rhs.informant
	}

}

extension Informing: CustomStringConvertible {

	public var description: String {
		"Look at secret informant \(informant)"
	}

}
