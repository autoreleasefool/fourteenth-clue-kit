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
