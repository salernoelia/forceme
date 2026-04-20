//
//  Item.swift
//  forceme
//
//  Created by Elia Salerno on 21.04.2026.
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
