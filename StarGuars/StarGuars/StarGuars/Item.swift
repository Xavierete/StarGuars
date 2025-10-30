//
//  Item.swift
//  StarGuars
//
//  Created by Xavier Moreno on 10/3/25.
//

import Foundation
import SwiftData

// MARK: - Item Model
@Model
final class Item {
    // MARK: - Properties
    var timestamp: Date
    var score: Int
    var level: Int
    var shipType: String
    
    // MARK: - Initialization
    init(timestamp: Date = .now, score: Int = 0, level: Int = 1, shipType: String = "starship") {
        self.timestamp = timestamp
        self.score = score
        self.level = level
        self.shipType = shipType
    }
} 