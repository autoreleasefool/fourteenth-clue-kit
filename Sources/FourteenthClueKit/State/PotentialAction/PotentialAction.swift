//
//  PotentialAction.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-22.
//

public enum PotentialAction {
	case inquiry(Inquiry)
	case informing(Informing)
}

extension PotentialAction: Comparable {

	public static func < (lhs: PotentialAction, rhs: PotentialAction) -> Bool {
		switch (lhs, rhs) {
		case (.inquiry(let l), .inquiry(let r)):
			return l < r
		case (.informing(let l), .informing(let r)):
			return l < r
		case (.inquiry, _):
			return true
		case (_, .inquiry):
			return false
		}
	}
	
}

extension PotentialAction: CustomStringConvertible {

	public var description: String {
		switch self {
		case .inquiry(let inquiry):
			return inquiry.description
		case .informing(let informing):
			return informing.description
		}
	}

}
