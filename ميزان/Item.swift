//
//  Item.swift
//  ميزان
//
//  Created by Eng Ammar Alzahrani on 13/01/2026.
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
