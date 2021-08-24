//
//  Card+Filter.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

extension Card {

	/// Category or color to filter the cards by
	public enum Filter: Equatable, CustomStringConvertible, Comparable {
		case color(Card.Color)
		case category(Card.Category)

		public init?(rawValue: String) {
			if let color = Card.Color(rawValue: rawValue) {
				self = .color(color)
			} else if let cat = Card.Category(rawValue: rawValue) {
				self = .category(cat)
			} else {
				return nil
			}
		}

		public var description: String {
			switch self {
			case .color(let color):
				return color.description
			case .category(let category):
				return category.description
			}
		}

		public static func < (lhs: Filter, rhs: Filter) -> Bool {
			switch (lhs, rhs) {
			case (.color(let left), .color(let right)):
				return left < right
			case (.category(let left), .category(let right)):
				return left < right
			case (.color, .category):
				return true
			case (.category, color):
				return false
			}
		}

		/// All cards matching the filter
		public var cards: Set<Card> {
			Card.allCardsMatching(filter: self)
		}
	}

}
