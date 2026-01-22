//
//  MassCounter.swift
//  MizanApp
//
//  Animated counter for displaying Mass with recent gain animation.
//

import SwiftUI

struct MassCounter: View {
    @EnvironmentObject var themeManager: ThemeManager
    let currentMass: Double
    let recentGain: Double

    @State private var displayedMass: Double = 0
    @State private var showGain: Bool = false

    var body: some View {
        HStack(spacing: MZSpacing.xs) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 16))
                .foregroundColor(themeManager.primaryColor)

            Text(formatMass(displayedMass))
                .font(MZTypography.dataLarge)
                .foregroundColor(themeManager.textPrimaryColor)
                .contentTransition(.numericText())

            if showGain && recentGain > 0 {
                Text("+\(Int(recentGain))")
                    .font(MZTypography.labelMedium)
                    .foregroundColor(themeManager.successColor)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .onChange(of: currentMass) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                displayedMass = newValue
            }
        }
        .onChange(of: recentGain) { _, newValue in
            if newValue > 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showGain = true
                }

                // Hide after delay
                _Concurrency.Task {
                    try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showGain = false
                        }
                    }
                }
            }
        }
        .onAppear {
            displayedMass = currentMass
        }
    }

    private func formatMass(_ mass: Double) -> String {
        if mass >= 10000 {
            return String(format: "%.1fK", mass / 1000)
        } else if mass >= 1000 {
            return String(format: "%.2fK", mass / 1000)
        }
        return String(format: "%.0f", mass)
    }
}
