//
//  PremiumTaskCard.swift
//  Mizan
//
//  A premium task card with neubrutalist 3D depth and glass effects
//

import SwiftUI

/// Premium task card with neubrutalist accents and glassmorphism
struct PremiumTaskCard: View {
    let task: Task
    let minHeight: CGFloat
    var hasTaskOverlap: Bool = false
    var overlappingTaskCount: Int = 0
    var onToggleCompletion: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    // MARK: - Drag Support (Optional)
    var hourHeight: CGFloat? = nil
    var prayers: [PrayerTime]? = nil
    var onTimeChange: ((Date) -> Void)? = nil
    var onDragNearEdge: ((DragEdgeDirection) -> Void)? = nil
    var scheduledTasks: [Task]? = nil  // For displacement preview

    /// Direction for auto-scroll edge detection
    enum DragEdgeDirection {
        case none, up, down
    }

    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPressed: Bool = false
    @State private var checkScale: CGFloat = 1.0
    @State private var completionGlow: CGFloat = 0
    @State private var appearOffset: CGFloat = 20
    @State private var appearOpacity: Double = 0

    // MARK: - Drag State
    @State private var isDragging: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var hasCollision: Bool = false
    @State private var cardGlobalY: CGFloat = 0
    @State private var currentEdgeDirection: DragEdgeDirection = .none

    /// Whether drag is enabled (requires hourHeight and prayers)
    private var isDragEnabled: Bool {
        hourHeight != nil && prayers != nil && onTimeChange != nil
    }

    private var taskColor: Color {
        Color(hex: task.colorHex)
    }

    /// Calculate proposed time based on drag offset
    private var proposedTime: Date? {
        guard let hourHeight = hourHeight, let startTime = task.scheduledStartTime else { return nil }
        let hoursDragged = Double(dragOffset) / Double(hourHeight)
        let secondsOffset = hoursDragged * 3600
        let newTime = startTime.addingTimeInterval(secondsOffset)
        return snapToGrid(newTime)
    }

    /// Check if proposed time collides with prayers
    private var proposedHasCollision: Bool {
        guard let prayers = prayers, let proposedTime = proposedTime else { return false }
        for prayer in prayers {
            if prayer.overlaps(with: proposedTime, duration: task.duration) {
                return true
            }
        }
        return false
    }

    /// Snap time to 15-minute grid
    private func snapToGrid(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let roundedMinute = Int(round(Double(minute) / 15.0) * 15.0) % 60
        let hourAdjustment = minute >= 53 ? 1 : 0

        var newComponents = components
        newComponents.minute = roundedMinute
        newComponents.hour = (components.hour ?? 0) + hourAdjustment

        return calendar.date(from: newComponents) ?? date
    }

    // MARK: - Body

    /// Direction of drag for drop zone indicator
    private var dragDirection: DragDirection {
        if dragOffset < -20 { return .up }
        if dragOffset > 20 { return .down }
        return .none
    }

    private enum DragDirection {
        case up, down, none
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Ghost preview at original position when dragging (shows where task came from)
            // No offset needed - it naturally stays at the original position in the ZStack
            if isDragging {
                ghostPreview
            }

            // Drop zone indicator - stays at original position, shows direction
            // No offset needed - it naturally stays at the original position in the ZStack
            if isDragging && !hasCollision && dragDirection != .none {
                dropZoneIndicatorPositioned
            }

            VStack(alignment: .leading, spacing: 4) {
                // Scroll edge indicator (when near top)
                if isDragging && currentEdgeDirection == .up {
                    scrollEdgeIndicator(direction: .up)
                }

                // Time row above the card (shows proposed time when dragging)
                timeRow

                // Main card with neubrutalist accent
                mainCard

                // Collision warning when dragging
                if isDragging && hasCollision {
                    collisionWarning
                }

                // Scroll edge indicator (when near bottom)
                if isDragging && currentEdgeDirection == .down {
                    scrollEdgeIndicator(direction: .down)
                }
            }
            .frame(minHeight: minHeight)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .offset(x: appearOffset, y: isDragging ? dragOffset : 0)
            .opacity(isDragging ? 0.95 : appearOpacity)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .zIndex(isDragging ? 100 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(task.title)، \(task.isCompleted ? "مكتملة" : "غير مكتملة")")
        .accessibilityValue("المدة \(task.duration.formattedDuration)، يبدأ \(task.startTime.formatted(date: .omitted, time: .shortened))")
        .onAppear {
            withAnimation(MZAnimation.cardAppear) {
                appearOffset = 0
                appearOpacity = 1.0
            }
        }
        .gesture(dragGesture)
    }

    // MARK: - Positioned Drop Zone Indicator

    private var dropZoneIndicatorPositioned: some View {
        VStack {
            // Show at top when dragging UP (task will land above original position)
            if dragDirection == .up {
                dropZoneIndicator
                Spacer()
            }

            // Show at bottom when dragging DOWN (task will land below original position)
            if dragDirection == .down {
                Spacer()
                dropZoneIndicator
            }
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: dragDirection)
    }

    // MARK: - Ghost Preview (Original Position)

    private var ghostPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Time label
            Text(task.startTime.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.textTertiaryColor)
                .padding(.leading, 4)

            // Ghost card outline
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .foregroundColor(taskColor.opacity(0.3))
                .frame(minHeight: minHeight - 24)
                .overlay(
                    Text("الموضع الأصلي")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(themeManager.textTertiaryColor)
                )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .opacity(0.5)
    }

    // MARK: - Drop Zone Indicator

    private var dropZoneIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasCollision ? themeManager.errorColor : themeManager.successColor)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(hasCollision ? themeManager.errorColor : themeManager.successColor)
                .frame(height: 2)

            Circle()
                .fill(hasCollision ? themeManager.errorColor : themeManager.successColor)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 8)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Edge Detection for Auto-Scroll

    /// Edge threshold for triggering auto-scroll (points from screen edge)
    private let edgeScrollThreshold: CGFloat = 100

    /// Detect if card is near screen edges and signal for auto-scroll
    private func detectEdgeProximity(globalY: CGFloat) {
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaTop: CGFloat = 100 // Account for navigation bar area
        let safeAreaBottom: CGFloat = 100 // Account for tab bar area

        let newDirection: DragEdgeDirection
        if globalY < safeAreaTop + edgeScrollThreshold {
            newDirection = .up
        } else if globalY > screenHeight - safeAreaBottom - edgeScrollThreshold {
            newDirection = .down
        } else {
            newDirection = .none
        }

        // Only trigger callback if direction changed
        if newDirection != currentEdgeDirection {
            currentEdgeDirection = newDirection
            onDragNearEdge?(newDirection)
        }
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press recognized, prepare for drag
                    if isDragEnabled && !isDragging {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isDragging = true
                        }
                        HapticManager.shared.trigger(.medium)
                    }
                case .second(true, let drag):
                    // Dragging
                    if isDragEnabled, let drag = drag {
                        dragOffset = drag.translation.height
                        hasCollision = proposedHasCollision
                        if hasCollision {
                            HapticManager.shared.trigger(.warning)
                        }

                        // Track global position for edge detection (auto-scroll)
                        let globalY = drag.location.y
                        detectEdgeProximity(globalY: globalY)
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                // Reset edge direction when drag ends
                if currentEdgeDirection != .none {
                    currentEdgeDirection = .none
                    onDragNearEdge?(.none)
                }

                if case .second(true, let drag) = value, isDragEnabled {
                    if hasCollision {
                        // Bounce back on collision
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dragOffset = 0
                            isDragging = false
                            hasCollision = false
                        }
                        HapticManager.shared.trigger(.error)
                    } else if let proposedTime = proposedTime, drag != nil {
                        // Apply new time
                        onTimeChange?(proposedTime)
                        HapticManager.shared.trigger(.success)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                            isDragging = false
                        }
                    } else {
                        // Reset
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset = 0
                            isDragging = false
                            hasCollision = false
                        }
                    }
                } else {
                    // Long press ended without drag - treat as tap
                    if !isDragging {
                        onTap?()
                        HapticManager.shared.trigger(.light)
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = 0
                        isDragging = false
                        hasCollision = false
                    }
                }
            }
    }

    // MARK: - Collision Warning

    private var collisionWarning: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text("يتعارض مع وقت صلاة")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(themeManager.textOnPrimaryColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.errorColor)
        .cornerRadius(8)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Scroll Edge Indicator

    private func scrollEdgeIndicator(direction: DragEdgeDirection) -> some View {
        HStack(spacing: 6) {
            Image(systemName: direction == .up ? "chevron.up.2" : "chevron.down.2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(themeManager.primaryColor)

            Text(direction == .up ? "التمرير للأعلى" : "التمرير للأسفل")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(themeManager.primaryColor)

            Image(systemName: direction == .up ? "chevron.up.2" : "chevron.down.2")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(themeManager.primaryColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(themeManager.primaryColor.opacity(0.15))
        )
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: currentEdgeDirection)
    }

    // MARK: - Time Row

    private var timeRow: some View {
        HStack(spacing: 6) {
            // Show proposed time when dragging, otherwise show current time
            if isDragging, let proposed = proposedTime {
                // Original time (struck through)
                Text(task.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(themeManager.textTertiaryColor)
                    .strikethrough(true, color: themeManager.textTertiaryColor)

                Image(systemName: "arrow.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(hasCollision ? themeManager.errorColor : themeManager.successColor)

                // New proposed time (highlighted)
                Text(proposed.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(hasCollision ? themeManager.errorColor : themeManager.successColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill((hasCollision ? themeManager.errorColor : themeManager.successColor).opacity(0.15))
                    )
            } else {
                Text(task.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(taskColor)

                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(themeManager.textTertiaryColor)

                Text(task.duration.formattedDuration)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.textSecondaryColor)
            }
        }
        .padding(.leading, 4)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    // MARK: - Main Card

    private var mainCard: some View {
        HStack(spacing: 0) {
            // Neubrutalist left accent bar
            accentBar

            // Glass content area
            cardContent
        }
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(glassBorder)
        .overlay(completionOverlay)
        .overlay(dragCollisionBorder)
        .overlapWarning(hasOverlap: hasTaskOverlap, overlapCount: overlappingTaskCount)
        .shadow(color: taskColor.opacity(isDragging ? 0.3 : 0.08), radius: isDragging ? 16 : 8, y: isDragging ? 8 : 3)
        .shadow(color: themeManager.backgroundColor.opacity(0.4), radius: 2, x: 2, y: 2) // Neubrutalist hard shadow
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .fill(themeManager.pressedColor.opacity(isPressed ? 0.1 : 0))
        )
        .opacity(task.isCompleted ? 0.7 : 1.0)
        .animation(MZAnimation.cardPress, value: isPressed)
        .contentShape(Rectangle()) // Make entire card tappable
        .contextMenu {
            // Edit option
            Button {
                onTap?()
            } label: {
                Label("تعديل", systemImage: "pencil")
            }

            // Toggle completion
            Button {
                onToggleCompletion?()
            } label: {
                Label(task.isCompleted ? "إلغاء الإكمال" : "إكمال", systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark")
            }

            Divider()

            // Delete option
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("حذف", systemImage: "trash")
            }
        }
    }

    // MARK: - Accent Bar (Neubrutalist)

    private var accentBar: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isDragging
                            ? [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)]
                            : [taskColor, taskColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Drag handle lines when draggable
            if isDragEnabled && !isDragging {
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(themeManager.textOnPrimaryColor.opacity(0.5))
                            .frame(width: 2, height: 1)
                    }
                }
            }
        }
        .frame(width: isDragging ? 6 : 4)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: 12) {
            // 3D Checkbox
            premiumCheckbox

            // Task info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted, color: themeManager.textSecondaryColor)
                        .lineLimit(2)

                    // Drag indicator when dragging
                    if isDragging {
                        Image(systemName: "arrow.up.and.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(themeManager.primaryColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                HStack(spacing: 6) {
                    // Task icon chip
                    HStack(spacing: 4) {
                        Image(systemName: task.icon)
                            .font(.system(size: 9))
                        Text(task.duration.formattedDuration)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(taskColor.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(taskColor.opacity(0.12))
                    )

                    if task.isCompleted {
                        completedBadge
                    }
                }
            }

            Spacer()

            // Duration ring
            durationRing
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Premium Checkbox

    private var premiumCheckbox: some View {
        Button {
            toggleCompletion()
        } label: {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        task.isCompleted ? themeManager.successColor : taskColor.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 24, height: 24)

                // Inner fill (when completed)
                if task.isCompleted {
                    Circle()
                        .fill(themeManager.successColor)
                        .frame(width: 18, height: 18)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                }

                // 3D bevel highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeManager.textOnPrimaryColor.opacity(0.15),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 22, height: 22)
            }
            .scaleEffect(checkScale)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? "إلغاء إكمال المهمة" : "إكمال المهمة")
        .accessibilityHint(task.isCompleted ? "اضغط لإلغاء إكمال المهمة" : "اضغط لوضع علامة إكمال")
    }

    // MARK: - Completed Badge

    private var completedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 8))
            Text("تم")
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(themeManager.successColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(themeManager.successColor.opacity(0.15))
        )
    }

    // MARK: - Duration Ring

    private var durationRing: some View {
        ZStack {
            Circle()
                .stroke(taskColor.opacity(0.15), lineWidth: 3)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: task.isCompleted ? 1.0 : 0)
                .stroke(themeManager.successColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Text(task.duration.formattedDuration)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(themeManager.textSecondaryColor)
        }
    }

    // MARK: - Drag Collision Border

    @ViewBuilder
    private var dragCollisionBorder: some View {
        if isDragging && hasCollision {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(themeManager.errorColor, lineWidth: 3)
        }
    }

    // MARK: - Glass Background

    private var glassBackground: some View {
        ZStack {
            themeManager.surfaceColor.opacity(0.7)

            LinearGradient(
                colors: [
                    themeManager.textOnPrimaryColor.opacity(0.06),
                    themeManager.textOnPrimaryColor.opacity(0.02),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )

            taskColor.opacity(0.04)
        }
    }

    // MARK: - Glass Border

    private var glassBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(
                LinearGradient(
                    colors: [
                        taskColor.opacity(0.3),
                        taskColor.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Completion Overlay

    @ViewBuilder
    private var completionOverlay: some View {
        if completionGlow > 0 {
            RoundedRectangle(cornerRadius: 14)
                .stroke(themeManager.successColor.opacity(completionGlow), lineWidth: 2)
                .blur(radius: 3)
        }
    }

    // MARK: - Toggle Completion

    private func toggleCompletion() {
        // Checkbox animation
        withAnimation(MZAnimation.bouncy) {
            checkScale = 0.7
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(MZAnimation.bouncy) {
                checkScale = 1.15
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(MZAnimation.bouncy) {
                checkScale = 1.0
            }
        }

        // Glow pulse on completion
        if !task.isCompleted {
            withAnimation(.easeOut(duration: 0.3)) {
                completionGlow = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    completionGlow = 0
                }
            }
        }

        HapticManager.shared.trigger(.success)
        onToggleCompletion?()
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "مراجعة القرآن",
                        duration: 30,
                        category: .worship
                    )
                    task.scheduledStartTime = Date()
                    return task
                }(),
                minHeight: 80
            )

            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "اجتماع العمل",
                        duration: 60,
                        category: .work
                    )
                    task.scheduledStartTime = Date().addingTimeInterval(3600)
                    return task
                }(),
                minHeight: 80
            )

            PremiumTaskCard(
                task: {
                    let task = Task(
                        title: "تمارين رياضية",
                        duration: 45,
                        category: .health
                    )
                    task.scheduledStartTime = Date().addingTimeInterval(7200)
                    task.isCompleted = true
                    return task
                }(),
                minHeight: 80
            )
        }
        .padding()
    }
    .background(ThemeManager().overlayColor.opacity(0.95))
    .environmentObject(ThemeManager())
}
