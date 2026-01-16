//
//  TimelineTrack.swift
//  Mizan
//
//  A clean timeline track component that creates visual continuity
//  between timeline segments with a vertical line and connector dots.
//

import SwiftUI

// MARK: - Timeline Track

/// Renders a vertical timeline track with an optional connector dot
struct TimelineTrack: View {
    let accentColor: Color
    var showDot: Bool = true
    var lineWidth: CGFloat = 2

    @EnvironmentObject var themeManager: ThemeManager

    private let dotSize: CGFloat = 6
    private let trackWidth: CGFloat = 16

    var body: some View {
        ZStack(alignment: .top) {
            // Continuous vertical line
            Rectangle()
                .fill(themeManager.textSecondaryColor.opacity(0.2))
                .frame(width: lineWidth)

            // Small connector dot (positioned at top)
            if showDot {
                Circle()
                    .fill(accentColor)
                    .frame(width: dotSize, height: dotSize)
                    .padding(.top, 8)
            }
        }
        .frame(width: trackWidth)
    }
}

// MARK: - Timeline Gap Track

/// A simpler track for gap segments - just the line, no dot
struct TimelineGapTrack: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Rectangle()
            .fill(themeManager.textSecondaryColor.opacity(0.2))
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .frame(width: 16)
    }
}

// MARK: - Timeline Row Wrapper

/// Wraps any timeline content with the track on the left
struct TimelineRow<Content: View>: View {
    let accentColor: Color
    var showDot: Bool = true
    @ViewBuilder let content: () -> Content

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            TimelineTrack(accentColor: accentColor, showDot: showDot)
                .environmentObject(themeManager)

            content()
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        TimelineRow(accentColor: .blue) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(height: 100)
                .padding(8)
        }

        TimelineRow(accentColor: .green) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.2))
                .frame(height: 80)
                .padding(8)
        }

        TimelineRow(accentColor: .orange, showDot: false) {
            Text("Gap")
                .frame(height: 40)
                .frame(maxWidth: .infinity)
        }

        TimelineRow(accentColor: .purple) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.2))
                .frame(height: 120)
                .padding(8)
        }
    }
    .padding()
    .background(Color.black.opacity(0.9))
    .environmentObject(ThemeManager())
}
