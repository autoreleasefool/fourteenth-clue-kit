//
//  SeedState.swift
//  FourteenthClueKit
//
//  Created by Joseph Roque on 2021-08-16.
//

import Foundation

typealias SeedState = [String: [CardSeed]]

struct CardSeed: Codable {
	let name: String
}
