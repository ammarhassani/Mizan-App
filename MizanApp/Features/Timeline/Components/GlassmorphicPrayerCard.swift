//
//  GlassmorphicPrayerCard.swift
//  Mizan
//
//  Performance-optimized glassmorphic prayer card.
//  NO continuous animations - only interaction-based animations.
//

import SwiftUI

/// Prayer status for display
enum PrayerStatus {
    case passed    // فائتة
    case current   // الحالية
    case upcoming  // القادمة

    var arabicLabel: String {
        switch self {
        case .passed: return "فائتة"
        case .current: return "الحالية"
        case .upcoming: return "القادمة"
        }
    }

    var icon: String {
        switch self {
        case .passed: return "checkmark.circle"
        case .current: return "clock.fill"
        case .upcoming: return "arrow.right.circle"
        }
    }
}

/// Glassmorphic prayer card - performance optimized
struct GlassmorphicPrayerCard: View {
    let prayer: PrayerTime
    let minHeight: CGFloat
    var preNawafil: NawafilPrayer? = nil
    var postNawafil: NawafilPrayer? = nil
    var isCurrentPrayer: Bool = false // Kept for CurrentPrayerHighlight wrapper compatibility
    var showDivineEffects: Bool = true // Kept for API compatibility, but ignored
    var onShowCountdown: (() -> Void)? = nil

    @EnvironmentObject var themeManager: ThemeManager
    @State private var appearScale: CGFloat = 0.98
    @State private var appearOpacity: Double = 0
    @State private var isPressed: Bool = false

    private var prayerColor: Color {
        Color(hex: prayer.colorHex)
    }

    /// Glass style values for glow effects
    private var glassValues: GlassStyleValues {
        themeManager.glassStyle(.prayer)
    }

    /// Determine prayer status based on current time
    private var prayerStatus: PrayerStatus {
        if prayer.hasPassed {
            return .passed
        } else if prayer.isCurrently {
            return .current
        } else {
            return .upcoming
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Time row above the card
            timeRow

            // Main card
            mainCard
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(prayer.displayName)، \(prayerStatus.arabicLabel)")
        .accessibilityValue("الأذان \(prayer.adhanTime.formatted(date: .omitted, time: .shortened))، المدة \(prayer.duration) دقيقة")
        .onAppear {
            withAnimation(MZAnimation.cardAppear) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(spacing: 6) {
            Text(prayer.adhanTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(prayerColor)

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(themeManager.textTertiaryColor)

            // Total duration (iqama wait + prayer)
            Text("\(prayer.duration + prayer.iqamaOffset) د")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .padding(.leading, 4)
    }

    // MARK: - Main Card

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (now includes status badge inline)
            cardHeader
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Athan info
            athanInfoRow
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            // Pre-nawafil chip
            if let pre = preNawafil {
                GlassmorphicNawafilChip(nawafil: pre, prayerColor: prayerColor, position: .before)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            // Iqama info
            iqamaInfoRow
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            // Post-nawafil chip
            if let post = postNawafil {
                GlassmorphicNawafilChip(nawafil: post, prayerColor: prayerColor, position: .after)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            } else {
                Spacer().frame(height: 6)
            }
        }
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(glassBorder)
        .overlay(currentPrayerGlow)
        .shadow(color: prayerColor.opacity(prayerStatus == .current ? 0.3 : 0.12), radius: prayerStatus == .current ? 12 : 8, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(MZAnimation.cardPress, value: isPressed)
    }

    /// Badge background color based on status
    private var statusBadgeBackgroundColor: Color {
        switch prayerStatus {
        case .passed:
            return themeManager.textSecondaryColor.opacity(0.6)
        case .current:
            return prayerColor
        case .upcoming:
            return themeManager.primaryColor.opacity(0.8)
        }
    }

    /// Badge text color based on status
    private var statusBadgeTextColor: Color {
        switch prayerStatus {
        case .passed:
            return themeManager.textOnPrimaryColor.opacity(0.9)
        case .current:
            return themeManager.textOnPrimaryColor
        case .upcoming:
            return themeManager.textOnPrimaryColor
        }
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack(spacing: 10) {
            // Prayer icon with glow
            ZStack {
                Circle()
                    .fill(prayerColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: prayer.prayerType.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(prayerColor)
                    .accessibilityHidden(true)
            }

            // Prayer name
            Text(prayer.displayName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer(minLength: 4)

            // Badges container - flexible layout for multiple badges
            HStack(spacing: 6) {
                prayerStatusBadgeInline

                // Jummah badge
                if prayer.isJummah {
                    jummahBadge
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            // Countdown button
            if let onShowCountdown = onShowCountdown {
                countdownButton(action: onShowCountdown)
            }
        }
    }

    // MARK: - Inline Status Badge (no offset)
    private var prayerStatusBadgeInline: some View {
        HStack(spacing: 4) {
            Image(systemName: prayerStatus.icon)
                .font(.system(size: 9, weight: .bold))

            Text(prayerStatus.arabicLabel)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(statusBadgeTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(statusBadgeBackgroundColor)
                .shadow(color: statusBadgeBackgroundColor.opacity(0.3), radius: 3, y: 1)
        )
    }

    private var jummahBadge: some View {
        Text("جمعة")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(themeManager.warningColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(themeManager.warningColor.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(themeManager.warningColor.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    private func countdownButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.trigger(.selection)
        } label: {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(prayerColor)
                .padding(10)
                .background(
                    Circle()
                        .fill(prayerColor.opacity(0.12))
                        .overlay(
                            Circle()
                                .stroke(prayerColor.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("عرض العد التنازلي")
        .accessibilityHint("اضغط لعرض العد التنازلي للصلاة")
    }

    // MARK: - Info Rows

    private var athanInfoRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 11))
                .foregroundColor(prayerColor.opacity(0.8))

            Text("الأذان")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()

            Text("\(prayer.iqamaOffset) د \(prayer.isJummah ? "خطبة" : "انتظار")")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    private var iqamaInfoRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 11))
                .foregroundColor(prayerColor.opacity(0.8))

            Text("الإقامة")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor)

            Spacer()

            Text("\(prayer.duration) د صلاة")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Visual Elements

    private var glassBackground: some View {
        ZStack {
            // Frosted base
            themeManager.surfaceColor.opacity(0.7)

            // Top highlight
            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(0.08),
                    themeManager.textOnPrimaryColor.opacity(0.02),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            // Accent tint
            prayerColor.opacity(0.06)
        }
    }

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [
                        prayerColor.opacity(0.4),
                        prayerColor.opacity(0.2),
                        prayerColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
    }

    @ViewBuilder
    private var currentPrayerGlow: some View {
        if prayerStatus == .current {
            // Static glow for current prayer (NO animation)
            // Uses theme-aware glow values when available
            let glowOpacity = glassValues.glowOpacity ?? 0.4
            let glowRadius = glassValues.glowRadius ?? 6

            RoundedRectangle(cornerRadius: 16)
                .stroke(prayerColor.opacity(glowOpacity), lineWidth: 2)
                .blur(radius: glowRadius * 0.5)

            RoundedRectangle(cornerRadius: 16)
                .stroke(prayerColor.opacity(glowOpacity * 0.5), lineWidth: 4)
                .blur(radius: glowRadius)
        }
    }
}

// MARK: - Nawafil Chip

enum NawafilPosition {
    case before, after
}

struct GlassmorphicNawafilChip: View {
    let nawafil: NawafilPrayer
    let prayerColor: Color
    let position: NawafilPosition

    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            // Moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 10))
                .foregroundColor(prayerColor.opacity(0.8))

            // Name and rakaat
            Text(nawafil.arabicName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(themeManager.textPrimaryColor.opacity(0.9))

            Text("•")
                .font(.system(size: 8))
                .foregroundColor(themeManager.textSecondaryColor)

            Text("\(nawafil.rakaat) ركعات")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeManager.textSecondaryColor)

            Spacer()

            // Completion indicator
            Image(systemName: nawafil.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(nawafil.isCompleted ? themeManager.successColor : themeManager.textSecondaryColor.opacity(0.4))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(prayerColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            prayerColor.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            GlassmorphicPrayerCard(
                prayer: PrayerTime(
                    date: Date(),
                    prayerType: .fajr,
                    adhanTime: Date(),
                    calculationMethod: .mwl
                ),
                minHeight: 120,
                isCurrentPrayer: true,
                onShowCountdown: {}
            )

            GlassmorphicPrayerCard(
                prayer: PrayerTime(
                    date: Date(),
                    prayerType: .dhuhr,
                    adhanTime: Date(),
                    calculationMethod: .mwl
                ),
                minHeight: 120,
                onShowCountdown: {}
            )

            GlassmorphicPrayerCard(
                prayer: PrayerTime(
                    date: Date(),
                    prayerType: .maghrib,
                    adhanTime: Date(),
                    calculationMethod: .mwl
                ),
                minHeight: 120
            )
        }
        .padding()
    }
    .background(ThemeManager().overlayColor.opacity(0.95))
    .environmentObject(ThemeManager())
}
