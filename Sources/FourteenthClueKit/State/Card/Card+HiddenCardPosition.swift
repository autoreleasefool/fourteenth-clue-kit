//
//  Card+HiddenCardPosition.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-30.
//

extension Card {

	public enum HiddenCardPosition: String, Hashable, Equatable, CustomStringConvertible, CaseIterable, Identifiable {
		case left
		case right

		public var description: String {
			rawValue
		}

		public var id: String {
			rawValue
		}

	}

}

extension Card.HiddenCardPosition: Comparable {

	public static func < (lhs: Card.HiddenCardPosition, rhs: Card.HiddenCardPosition) -> Bool {
		if lhs == rhs { return false }
		switch (lhs, rhs) {
		case (.left, _):
			return true
		case (_, .left):
			return false
		case (.right, _):
			return true
		}
	}
}
