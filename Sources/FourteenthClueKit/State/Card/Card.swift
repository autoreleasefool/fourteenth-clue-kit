//
//  Card.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

/// Represents all of the cards in the game.
public enum Card: String, CaseIterable, Hashable {

	case harbor
	case library
	case market
	case museum
	case park
	case parlor
	case plaza
	case racecourse
	case railcar
	case theater

	case butcher
	case coachman
	case countess
	case dancer
	case duke
	case florist
	case maid
	case nurse
	case officer
	case sailor

	case blowgun
	case bow
	case candlestick
	case crossbow
	case gun
	case hammer
	case knife
	case poison
	case rifle
	case sword

	/// Capitalized name of the card
	public var name: String {
		self.rawValue.capitalized
	}

	/// Creates a set of cards suitable for a game with the given number of players
	/// - Parameter forPlayerCount: number of players to get a set of cards suitable for
	public static func cardSet(forPlayerCount playerCount: Int) -> Set<Card> {
		var availableCards = Set(Card.allCases)

		switch playerCount {
		case 2:
			availableCards.subtract(Card.orangeCards)
			fallthrough
		case 3:
			availableCards.subtract(Card.whiteCards)
			fallthrough
		case 4:
			availableCards.subtract(Card.brownCards)
			fallthrough
		case 5:
			availableCards.subtract(Card.grayCards)
		default:
			break
		}

		return availableCards
	}
}

// MARK: - Category

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

		/// Gender of the person cards
		public enum Gender: String, Hashable, Equatable, Identifiable {
			case man
			case woman

			public var id: String {
				rawValue
			}
		}

		/// Presence of the location cards
		public enum Presence: String, Hashable, Equatable, Identifiable {
			case indoors
			case outdoors

			public var id: String {
				rawValue
			}
		}

		/// Class of the weapon cards
		public enum Class: String, Hashable, Equatable, Identifiable {
			case melee
			case ranged

			public var id: String {
				rawValue
			}
		}

		public var id: String {
			description
		}

		public var description: String {
			switch self {
			case .person(.man):
				return "Male"
			case .person(.woman):
				return "Female"
			case .location(.indoors):
				return "Indoors"
			case .location(.outdoors):
				return "Outdoors"
			case .weapon(.melee):
				return "Melee"
			case .weapon(.ranged):
				return "Ranged"
			}
		}

		public static var allCases: [Category] {
			[.person(.man), .person(.woman), .location(.indoors), .location(.outdoors), .weapon(.melee), .weapon(.ranged)]
		}

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
		Set(Card.allCases.filter { card in
			switch filter {
			case .color(let color):
				return color == card.color
			case .category(let category):
				return category == card.category
			}
		})
	}

	// MARK: People

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

	// MARK: Locations

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

	// MARK: Weapons

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

// MARK: - Color

extension Card {

	/// Color for each of the cards
	public enum Color: String, CaseIterable, CustomStringConvertible, Identifiable, Comparable {

		case purple
		case pink
		case red
		case green
		case yellow
		case blue
		case orange
		case white
		case brown
		case gray

		public var id: String {
			rawValue
		}

		public var description: String {
			rawValue.capitalized
		}

		public static func < (lhs: Color, rhs: Color) -> Bool {
			if lhs == rhs { return false }
			switch (lhs, rhs) {
			case (.purple, _): return true
			case (_, .purple): return false
			case (.pink, _): return true
			case (_, .pink): return false
			case (.red, _): return true
			case (_, .red): return false
			case (.green, _): return true
			case (_, .green): return false
			case (.yellow, _): return true
			case (_, .yellow): return false
			case (.blue, _): return true
			case (_, .blue): return false
			case (.orange, _): return true
			case (_, .orange): return false
			case (.white, _): return true
			case (_, .white): return false
			case (.brown, _): return true
			case (_, .brown): return false
			case (.gray, _): return true
			case (_, .gray): return false
			case (_, _): return false
			}
		}

	}

	/// Color of the card
	public var color: Color {
		switch self {
		case .officer, .parlor, .knife:
			return .purple
		case .duke, .market, .crossbow:
			return .pink
		case .butcher, .library, .poison:
			return .red
		case .countess, .park, .sword:
			return .green
		case .nurse, .museum, .blowgun:
			return .yellow
		case .maid, .harbor, .rifle:
			return .blue
		case .dancer, .theater, .gun:
			return .orange
		case .sailor, .plaza, .candlestick:
			return .white
		case .florist, .railcar, .hammer:
			return .brown
		case .coachman, .racecourse, .bow:
			return .gray
		}
	}

	/// All of the purple cards
	public static let purpleCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .purple }) }()
	/// All of the pink cards
	public static let pinkCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .pink }) }()
	/// All of the red cards
	public static let redCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .red }) }()
	/// All of the green cards
	public static let greenCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .green }) }()
	/// All of the yellow cards
	public static let yellowCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .yellow }) }()
	/// All of the blue cards
	public static let blueCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .blue }) }()
	/// All of the orange cards
	public static let orangeCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .orange }) }()
	/// All of the white cards
	public static let whiteCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .white }) }()
	/// All of the brown cards
	public static let brownCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .brown }) }()
	/// All of the gray cards
	public static let grayCards: Set<Card> = { Set(Card.allCases.filter { $0.color == .gray }) }()

}

// MARK: - Filter

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

// MARK: - Comparable

extension Card: Comparable {
	public static func < (lhs: Card, rhs: Card) -> Bool {
		(lhs.color, lhs.category, lhs.rawValue) < (rhs.color, rhs.category, rhs.rawValue)
	}
}

// MARK: - Set

extension Set where Element == Card {

	// MARK: Basic categories

	/// People in the set
	public var people: Set<Card> { self.intersection(Card.peopleCards) }
	/// Locations in the set
	public var locations: Set<Card> { self.intersection(Card.locationsCards) }
	/// Weapons in the set
	public var weapons: Set<Card> { self.intersection(Card.weaponsCards) }

	// MARK: Categories

	/// Men in the set
	public var men: Set<Card> { self.intersection(Card.menCards) }
	/// Women in the set
	public var women: Set<Card> { self.intersection(Card.womenCards) }
	/// Indoors locations in the set
	public var indoors: Set<Card> { self.intersection(Card.indoorsCards) }
	/// Outdoors cards in the set
	public var outdoors: Set<Card> { self.intersection(Card.outdoorsCards) }
	/// Ranged cards in the set
	public var ranged: Set<Card> { self.intersection(Card.rangedCards) }
	/// Melee cards in the set
	public var melee: Set<Card> { self.intersection(Card.meleeCards) }

	// MARK: Colors

	/// Purple cards in the set
	public var purpleCards: Set<Card> { self.intersection(Card.purpleCards) }
	/// Pink cards in the set
	public var pinkCards: Set<Card> { self.intersection(Card.pinkCards) }
	/// Red cards in the set
	public var redCards: Set<Card> { self.intersection(Card.redCards) }
	/// Green cards in the set
	public var greenCards: Set<Card> { self.intersection(Card.greenCards) }
	/// Yellow cards in the set
	public var yellowCards: Set<Card> { self.intersection(Card.yellowCards) }
	/// Blue cards in the set
	public var blueCards: Set<Card> { self.intersection(Card.blueCards) }
	/// Orange cards in the set
	public var orangeCards: Set<Card> { self.intersection(Card.orangeCards) }
	/// White cards in the set
	public var whiteCards: Set<Card> { self.intersection(Card.whiteCards) }
	/// Brown cards in the set
	public var brownCards: Set<Card> { self.intersection(Card.brownCards) }
	/// Gray cards in the set
	public var grayCards: Set<Card> { self.intersection(Card.grayCards) }

	/// Cards matching a given filter
	public func matching(filter: Card.Filter) -> Set<Card> {
		self.intersection(Card.allCardsMatching(filter: filter))
	}

}

