//
//  Card+Color.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-23.
//

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

		// swiftlint:disable:next cyclomatic_complexity
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

	/// Return a set of all cards matching the given Color
	public static func allCardsMatching(color: Color) -> Set<Card> {
		switch color {
		case .purple: return purpleCards
		case .pink: return pinkCards
		case .red: return redCards
		case .green: return greenCards
		case .yellow: return yellowCards
		case .blue: return blueCards
		case .orange: return orangeCards
		case .white: return whiteCards
		case .brown: return brownCards
		case .gray: return grayCards
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
