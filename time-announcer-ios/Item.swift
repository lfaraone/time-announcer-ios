//
//  Item.swift
//  time-announcer-ios
//
//  Created by Luke Faraone on 2025-11-04.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
