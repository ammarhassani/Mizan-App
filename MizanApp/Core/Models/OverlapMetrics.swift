//
//  OverlapMetrics.swift
//  Mizan
//
//  Calculates overlap metrics between time-based items for bubble squeeze effect.
//

import SwiftUI

/// Calculates overlap metrics between two time-based items
struct OverlapMetrics {
    let overlapDuration: TimeInterval  // How long they overlap (seconds)
    let overlapPercentage: CGFloat     // 0.0 - 1.0 (relative to shorter item)
    let squeezeAmount: CGFloat         // 0.0 - 0.3 (visual compression factor)

    init(
        itemAStart: Date, itemAEnd: Date,
        itemBStart: Date, itemBEnd: Date
    ) {
        // Calculate overlap window
        let overlapStart = max(itemAStart, itemBStart)
        let overlapEnd = min(itemAEnd, itemBEnd)

        if overlapEnd > overlapStart {
            overlapDuration = overlapEnd.timeIntervalSince(overlapStart)

            // Calculate as percentage of the shorter item
            let durationA = itemAEnd.timeIntervalSince(itemAStart)
            let durationB = itemBEnd.timeIntervalSince(itemBStart)
            let shorterDuration = min(durationA, durationB)

            overlapPercentage = shorterDuration > 0
                ? CGFloat(overlapDuration / shorterDuration)
                : 0

            // Convert to squeeze: max 30% compression for 100% overlap
            squeezeAmount = min(overlapPercentage * 0.3, 0.3)
        } else {
            overlapDuration = 0
            overlapPercentage = 0
            squeezeAmount = 0
        }
    }

    /// Pre-computed overlap levels for common scenarios
    static let none = OverlapMetrics(squeezeAmount: 0)
    static let light = OverlapMetrics(squeezeAmount: 0.08)   // ~25% overlap
    static let medium = OverlapMetrics(squeezeAmount: 0.15)  // ~50% overlap
    static let heavy = OverlapMetrics(squeezeAmount: 0.25)   // ~80% overlap

    private init(squeezeAmount: CGFloat) {
        self.overlapDuration = 0
        self.overlapPercentage = squeezeAmount > 0 ? squeezeAmount / 0.3 : 0
        self.squeezeAmount = squeezeAmount
    }
}
