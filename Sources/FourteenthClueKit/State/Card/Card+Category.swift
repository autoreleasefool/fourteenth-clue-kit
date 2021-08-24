//
//  Card+Category.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

extension Card {

	/// Cards are either a person, location, or weapon. There are subclasses of each category.
	public enum Category: Hashable, Equatable, CaseIterable, CustomStringConvertible, Identifiable, Comparable {

		case person(Gender)
		case location(Presence)
		case weapon(Class)

		public init?(rawValue: String) {
			if let gender = Gender(rawValue: rawValue) {
				self = .person(gender)
			} else if let presence = Presence(rawValue: rawValue) {
				self = .location(presence)
			} else if let `class` = Class(rawValue: rawValue) {
				self = .weapon(`class`)
			} else {
				return nil
			}
		}

		public var id: String {
			description
		}

		public var description: String {
			switch self {
			case .person(let gender):
				return gender.description
			case .location(let presence):
				return presence.description
			case .weapon(let `class`):
				return `class`.description
			}
		}

		public static var allCases: [Category] {
			[.person(.man), .person(.woman), .location(.indoors), .location(.outdoors), .weapon(.melee), .weapon(.ranged)]
		}

		// swiftlint:disable:next cyclomatic_complexity
		public static func < (lhs: Category, rhs: Category) -> Bool {
			if lhs == rhs { return false }
			switch (lhs, rhs) {
			case (.person(.man), _): return true
			case (_, .person(.man)): return false
			case (.person(.woman), _): return true
			case (_, .person(.woman)): return false
			case (.location(.indoors), _): return true
			case (_, .location(.indoors)): return false
			case (.location(.outdoors), _): return true
			case (_, .location(.outdoors)): return false
			case (.weapon(.ranged), _): return true
			case (_, .weapon(.ranged)): return false
			case (.weapon(.melee), _): return true
			case (_, .weapon(.melee)): return false
			}
		}

	}

	/// Category of the card
	public var category: Category {
		switch self {
		case .harbor, .market, .park, .plaza, .racecourse:
			return .location(.outdoors)
		case .library, .museum, .parlor, .railcar, .theater:
			return .location(.indoors)

		case .butcher, .coachman, .duke, .officer, .sailor:
			return .person(.man)
		case .countess, .dancer, .florist, .maid, .nurse:
			return .person(.woman)

		case .blowgun, .bow, .crossbow, .gun, .rifle:
			return .weapon(.ranged)
		case .candlestick, .hammer, .knife, .poison, .sword:
			return .weapon(.melee)
		}
	}

	public static func allCardsMatching(filter: Filter) -> Set<Card> {
		switch filter {
		case .color(let color):
			return Card.allCardsMatching(color: color)
		case .category(let category):
			return Card.allCardsMatching(category: category)
		}
	}

	public static func allCardsMatching(category: Category) -> Set<Card> {
		switch category {
		case .person(.man): return menCards
		case .person(.woman): return womenCards
		case .location(.indoors): return indoorsCards
		case .location(.outdoors): return outdoorsCards
		case .weapon(.melee): return meleeCards
		case .weapon(.ranged): return rangedCards
		}
	}

}

// MARK: - People

extension Card.Category {

	/// Gender of the person cards
	public enum Gender: String, Hashable, Equatable, Identifiable, CustomStringConvertible {
		case man
		case woman

		public var id: String {
			rawValue
		}

		public var description: String {
			switch self {
			case .man:
				return "Male"
			case .woman:
				return "Female"
			}
		}
	}

}

extension Card {

	/// All of the men people cards
	public static let menCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .person(.man) }) }()
	/// All of the women people cards
	public static let womenCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .person(.woman) }) }()
	/// All of the people cards
	public static let peopleCards: Set<Card> = { menCards.union(womenCards) }()

	/// `true` if this card is a person
	public var isPerson: Bool {
		Card.peopleCards.contains(self)
	}

}

// MARK: - Location

extension Card.Category {

	/// Presence of the location cards
	public enum Presence: String, Hashable, Equatable, Identifiable, CustomStringConvertible {
		case indoors
		case outdoors

		public var id: String {
			rawValue
		}

		public var description: String {
			switch self {
			case .indoors:
				return "Indoors"
			case .outdoors:
				return "Outdoors"
			}
		}
	}

}

extension Card {

	/// All of the outdoors location cards
	public static let outdoorsCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .location(.outdoors) }) }()
	/// All of the indoors location cards
	public static let indoorsCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .location(.indoors) }) }()
	/// All of the locations cards
	public static let locationsCards: Set<Card> = { outdoorsCards.union(indoorsCards) }()

	/// `true` if this card is a location
	public var isLocation: Bool {
		Card.locationsCards.contains(self)
	}

}

// MARK: - Weapons

extension Card.Category {

	/// Class of the weapon cards
	public enum Class: String, Hashable, Equatable, Identifiable, CustomStringConvertible {
		case melee
		case ranged

		public var id: String {
			rawValue
		}

		public var description: String {
			switch self {
			case .melee:
				return "Melee"
			case .ranged:
				return "Ranged"
			}
		}
	}

}

extension Card {

	/// All of the ranged weapon cards
	public static let rangedCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .weapon(.ranged) }) }()
	/// All of the melee weapon cards
	public static let meleeCards: Set<Card> = { Set(Card.allCases.filter { $0.category == .weapon(.melee) }) }()
	/// All of the weapon cards
	public static let weaponsCards: Set<Card> = { rangedCards.union(meleeCards) }()

	/// `true` if this card is a weapon
	public var isWeapon: Bool {
		Card.weaponsCards.contains(self)
	}

}
