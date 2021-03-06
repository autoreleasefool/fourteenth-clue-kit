//
//  GameState.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

/// State of the game
public struct GameState {

	/// Unique ID for the state
	public let id = UUID()
	/// Players in the state
	public let players: [Player]
	/// Secret informants in th state
	public let secretInformants: [SecretInformant]
	/// Playable cards
	public let cards: Set<Card>
	/// Actions taken in the game
	public let actions: [Action]

	public init(playerCount: Int) {
		self.init(
			players: (1...playerCount).map { Player(ordinal: $0) },
			secretInformants: GameState.secretInformants(forPlayerCount: playerCount),
			actions: [],
			cards: Card.cardSet(forPlayerCount: playerCount)
		)
	}

	public init(playerNames: [String]) {
		self.init(
			players: playerNames.map {
				Player(
					name: $0,
					hidden: HiddenCardSet(left: nil, right: nil),
					mystery: MysteryCardSet(person: nil, location: nil, weapon: nil),
					magnifyingGlasses: 1
				)
			},
			secretInformants: GameState.secretInformants(forPlayerCount: playerNames.count),
			actions: [],
			cards: Card.cardSet(forPlayerCount: playerNames.count)
		)
	}

	public init?(seed: String) {
		guard let data = seed.data(using: .utf8),
					let seedState = try? JSONDecoder().decode(SeedState.self, from: data)
		else {
			return nil
		}

		let firstPlayerSeed = seedState
			.first(where: { $0.value.count == 2 })!
		let firstPlayerCards = firstPlayerSeed.value.compactMap { Card(rawValue: $0.name.lowercased()) }
		let otherSeeds = seedState.filter { $0.value.count == 3 }.sorted { $0.key < $1.key }

		self.init(
			players: [
				Player(
					name: firstPlayerSeed.key,
					hidden: HiddenCardSet(
						left: firstPlayerCards.first!,
						right: firstPlayerCards.last!
					),
					mystery: MysteryCardSet(),
					magnifyingGlasses: 1
				),
			] + otherSeeds.map {
				let cards = Set($0.value.compactMap { Card(rawValue: $0.name.lowercased()) })
				return Player(
					name: $0.key,
					hidden: HiddenCardSet(),
					mystery: MysteryCardSet(
						person: cards.people.first!,
						location: cards.locations.first!,
						weapon: cards.weapons.first!
					),
					magnifyingGlasses: 1
				)
			},
			secretInformants: GameState.secretInformants(forPlayerCount: seedState.count),
			actions: [],
			cards: Card.cardSet(forPlayerCount: seedState.count)
		)
	}

	private init(players: [Player], secretInformants: [SecretInformant], actions: [Action], cards: Set<Card>) {
		assert((2...6).contains(players.count))
		self.players = players
		self.secretInformants = secretInformants
		self.actions = actions
		self.cards = cards
	}

	public static func secretInformants(forPlayerCount playerCount: Int) -> [SecretInformant] {
		zip("ABCDEFGH", (0..<8 - ((playerCount - 2) * 2)))
			.map { SecretInformant(name: String($0.0), card: nil) }
	}

	// MARK: Mutations

	/// Update a player's properties
	/// - Parameter player: the player to update
	public func with(player: Player, atIndex index: Int) -> GameState {
		var updatedPlayers = players
		updatedPlayers[index] = player
		return .init(players: updatedPlayers, secretInformants: secretInformants, actions: actions, cards: cards)
	}

	/// Update a player's secret informants
	/// - Parameter secretInformant: the secret informant to update
	public func with(secretInformant: SecretInformant) -> GameState {
		guard let index = secretInformants.firstIndex(where: { $0.name == secretInformant.name }) else { return self }
		var updatedInformants = secretInformants
		updatedInformants[index] = secretInformant
		return .init(players: players, secretInformants: updatedInformants, actions: actions, cards: cards)
	}

	/// Add an action taken to the state's actions
	/// - Parameter action: the action to append
	public func appending(action: Action) -> GameState {
		return .init(
			players: self.players.map { $0.resolvingAction(action, in: self) },
			secretInformants: secretInformants,
			actions: actions + [action],
			cards: cards
		)
	}

	/// Remove an action from the state
	/// - Parameter action: the action to remove
	public func removing(action: Action) -> GameState {
		guard let actionIndex = self.actions.firstIndex(of: action) else { return self }
		var actions = self.actions
		actions.remove(at: actionIndex)

		let defaultGlassCount = numberOfPlayers == 2 ? 0 : 1

		var players = players.map {
			Player(name: $0.name, hidden: $0.hidden, mystery: $0.mystery, magnifyingGlasses: defaultGlassCount)
		}
		var state = GameState(players: players, secretInformants: secretInformants, actions: [], cards: cards)
		actions.forEach { action in
			players = players.map { $0.resolvingAction(action, in: state) }
			state = state.with(players: players, actions: actions)
		}

		return .init(players: players, secretInformants: secretInformants, actions: actions, cards: cards)
	}

	internal func with(players: [Player], actions: [Action]) -> GameState {
		.init(players: players, secretInformants: secretInformants, actions: actions, cards: cards)
	}

	/// Remove a set of actions from the state
	/// - Parameter atOffsets: indices of the actions to remove
	public func removingActions(atOffsets offsets: IndexSet) -> GameState {
		var actions = self.actions
		offsets.map { actions[$0] }
			.forEach {
				guard let actionIndex = actions.firstIndex(of: $0) else { return }
				actions.remove(at: actionIndex)
			}
		return .init(players: players, secretInformants: secretInformants, actions: actions, cards: cards)
	}

	// MARK: Properties

	/// Number of players in the game
	public var numberOfPlayers: Int {
		players.count
	}

	/// Number of informants in the game
	public var numberOfInformants: Int {
		secretInformants.count
	}

	/// Number of unrevealed informants in the game
	public var numberOfUnknownInformants: Int {
		secretInformants.compactMap { $0.card }.count
	}

	/// `true` if there are more than 2 players, meaning magnifying glasses must be tracked
	public var isTrackingMagnifyingGlasses: Bool {
		numberOfPlayers > 2
	}

	/// `true` if there's enough information about the game to begin solving
	/// (opponent mysteries + player's hidden cards are defined)
	public var isSolveable: Bool {
		players.first!.isSolveable(asFirstPlayer: true) &&
			players.dropFirst().allSatisfy { $0.isSolveable(asFirstPlayer: false) }
	}

	/// `true` if this state is identical to `nextState`, expect with less actions indicated
	/// - Parameter nextState: the state to compare to
	public func isEarlierState(of nextState: GameState) -> Bool {
		self.players == nextState.players &&
			self.secretInformants == nextState.secretInformants &&
			self.cards == nextState.cards &&
			self.actions.count < nextState.actions.count &&
			zip(self.actions, nextState.actions).allSatisfy { $0 == $1 }
	}

	/// `true` if the given action has already been taken in the state
	public func actionHasBeenTaken(action: PotentialAction) -> Bool {
		switch action {
		case .inquiry(let inquiry):
			return playerHasBeenAsked(inquiry: inquiry)
		case .informing(let informing):
			return hasBeenInformed(by: informing.informant)
		}
	}

	/// `true` if the player in `inquiry` has already been asked the query before
	/// - Parameter inquiry: the inquiry to check
	public func playerHasBeenAsked(inquiry: Inquiry) -> Bool {
		actions.contains {
			guard case let .inquire(inquisition) = $0 else { return false }
			return inquisition.answeringPlayer == inquiry.player &&
				inquisition.filter == inquiry.filter &&
				inquisition.includingCardOnSide == inquiry.includingCardOnSide
		}
	}

	/// `true` if an Informant with the given name `informant` has been revealed
	public func hasBeenInformed(by informant: String) -> Bool {
		secretInformants.contains { $0.name == informant && $0.card != nil }
	}

	/// Returns the set of cards visible to the player
	/// - Parameter toPlayer: returns cards visible to this player
	public func cardsVisible(toPlayer targetPlayer: Player) -> Set<Card> {
		Set(players.flatMap { player in
			return targetPlayer.id == player.id
				? player.hidden.cards
				: player.mystery.cards
		})
	}

	/// Returns the set of cards visible to the first player (you), excluding the cards of a certain player.
	/// This set of cards is the overlap visible to both of you.
	/// - Parameter excludingPlayer: the player to exclude
	public func mysteryCardsVisibleToMe(excludingPlayer excludedPlayer: String) -> Set<Card> {
		players.dropFirst()
			.reduce(into: Set<Card>()) { cards, player in
				guard player.id != excludedPlayer else { return }
				cards.formUnion(player.mystery.cards)
			}
	}

	/// Returns the set of cards in the state for a given filter.
	public func cards(forFilter filter: Card.Filter) -> Set<Card> {
		switch filter {
		case .color(let color):
			return cards(forColor: color)
		case .category(let category):
			return cards(forCategory: category)
		}
	}

	/// Returns the set of cards in the state for a given category.
	public func cards(forCategory category: Card.Category) -> Set<Card> {
		switch category {
		case .person(.man): return menCards
		case .person(.woman): return womenCards
		case .location(.indoors): return indoorsCards
		case .location(.outdoors): return outdoorsCards
		case .weapon(.melee): return meleeCards
		case .weapon(.ranged): return rangedCards
		}
	}

	/// Returns the set of cards in the state for a given color.
	public func cards(forColor color: Card.Color) -> Set<Card> {
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

	// MARK: - Cards

	/// Cards which haven't been set to any player's mystery, hidden cards, or informants
	public var unallocatedCards: Set<Card> {
		cards
			.subtracting(players.flatMap { $0.mystery.cards })
			.subtracting(players.flatMap { $0.hidden.cards })
			.subtracting(secretInformants.compactMap { $0.card })
	}

	/// Cards which were initially not visible at the start of the game
	public var initialUnknownCards: Set<Card> {
		cards
			.subtracting(players.first!.hidden.cards)
			.subtracting(players.dropFirst().flatMap { $0.mystery.cards })
	}

	/// All cards in the state
	public var allCards: Set<Card> {
		cards
	}

	/// Purple cards in the state
	public var purpleCards: Set<Card> { cards.intersection(Card.purpleCards) }
	/// Pink cards in the state
	public var pinkCards: Set<Card> { cards.intersection(Card.pinkCards) }
	/// Red cards in the state
	public var redCards: Set<Card> { cards.intersection(Card.redCards) }
	/// Green cards in the state
	public var greenCards: Set<Card> { cards.intersection(Card.greenCards) }
	/// Yellow cards in the state
	public var yellowCards: Set<Card> { cards.intersection(Card.yellowCards) }
	/// Blue cards in the state
	public var blueCards: Set<Card> { cards.intersection(Card.blueCards) }
	/// Orange cards in the state
	public var orangeCards: Set<Card> { cards.intersection(Card.orangeCards) }
	/// White cards in the state
	public var whiteCards: Set<Card> { cards.intersection(Card.whiteCards) }
	/// Brown cards in the state
	public var brownCards: Set<Card> { cards.intersection(Card.brownCards) }
	/// Gray cards in the state
	public var grayCards: Set<Card> { cards.intersection(Card.grayCards) }

	// MARK: People

	/// People cards in the state
	public var peopleCards: Set<Card> { cards.intersection(Card.peopleCards) }
	/// Men people cards in the state
	public var menCards: Set<Card> { cards.intersection(Card.menCards) }
	/// Women people cards in the state
	public var womenCards: Set<Card> { cards.intersection(Card.womenCards) }

	// MARK: Locations

	/// Location cards in the state
	public var locationsCards: Set<Card> { cards.intersection(Card.locationsCards) }
	/// Outdoors location cards in the state
	public var outdoorsCards: Set<Card> { cards.intersection(Card.outdoorsCards) }
	/// Indoors location cards in the state
	public var indoorsCards: Set<Card> { cards.intersection(Card.indoorsCards) }

	// MARK: Weapons

	/// Weapon cards in the state
	public var weaponsCards: Set<Card> { cards.intersection(Card.weaponsCards) }
	/// Ranged weapon cards in the state
	public var rangedCards: Set<Card> { cards.intersection(Card.rangedCards) }
	/// Melee weapon cards in the state
	public var meleeCards: Set<Card> { cards.intersection(Card.meleeCards) }

}
