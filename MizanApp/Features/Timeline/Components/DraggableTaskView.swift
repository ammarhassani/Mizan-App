//
//  DraggableTaskView.swift
//  Mizan
//
//  Draggable task block with collision detection
//

import SwiftUI
import SwiftData

struct DraggableTaskView: View {
    let task: Task
    let hourHeight: CGFloat
    let baseTime: Date
    let prayers: [PrayerTime]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var hasCollision = false
    @State private var showBounceAnimation = false

    // MARK: - Computed Properties

    private var currentYPosition: CGFloat {
        guard let startTime = task.scheduledStartTime else { return 0 }
        let interval = startTime.timeIntervalSince(baseTime)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight + dragOffset.height
    }

    private var blockHeight: CGFloat {
        CGFloat(task.duration) / 60.0 * hourHeight
    }

    private var proposedTime: Date {
        let draggedHours = Double(currentYPosition / hourHeight)
        let proposedDate = baseTime.addingTimeInterval(draggedHours * 3600)
        return snapToGrid(proposedDate)
    }

    private var proposedHasCollision: Bool {
        for prayer in prayers {
            if prayer.overlaps(with: proposedTime, duration: task.duration) {
                return true
            }
        }
        return false
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color(hex: task.colorHex)
                .cornerRadius(themeManager.cornerRadius(.medium))
                .shadow(
                    color: themeManager.textPrimaryColor.opacity(isDragging ? 0.3 : 0.1),
                    radius: isDragging ? 12 : 4,
                    x: 0,
                    y: isDragging ? 8 : 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius(.medium))
                        .strokeBorder(
                            hasCollision ? themeManager.errorColor : Color.clear,
                            lineWidth: hasCollision ? 3 : 0
                        )
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Drag handle indicator
                    if !isDragging {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 16))
                            .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.6))
                            .accessibilityLabel("اسحب لتغيير وقت المهمة")
                            .accessibilityHint("اسحب للأعلى أو للأسفل لتغيير الوقت")
                    }

                    Image(systemName: task.icon)
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.textOnPrimaryColor)

                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.textOnPrimaryColor)
                        .lineLimit(2)

                    Spacer()

                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(themeManager.textOnPrimaryColor)
                    }
                }

                Text(task.duration.formattedDuration)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.9))

                if let notes = task.notes, !notes.isEmpty, blockHeight > 80 {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.textOnPrimaryColor.opacity(0.8))
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                Spacer()

                // Collision warning
                if isDragging && hasCollision {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text("يتعارض مع وقت صلاة")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(themeManager.textOnPrimaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.errorColor.opacity(0.9))
                    .cornerRadius(6)
                }
            }
            .padding(10)
        }
        .frame(height: blockHeight)
        .offset(y: showBounceAnimation ? currentYPosition : yPosition)
        .offset(y: dragOffset.height)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showBounceAnimation)
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture())
                .onChanged { value in
                    handleDragChanged(value: value)
                }
                .onEnded { value in
                    handleDragEnded(value: value)
                }
        )
    }

    // MARK: - Computed Position

    private var yPosition: CGFloat {
        guard let startTime = task.scheduledStartTime else { return 0 }
        let interval = startTime.timeIntervalSince(baseTime)
        let hours = interval / 3600
        return CGFloat(hours) * hourHeight
    }

    // MARK: - Gesture Handlers

    private func handleDragChanged(value: SequenceGesture<LongPressGesture, DragGesture>.Value) {
        switch value {
        case .first(true):
            // Long press detected - prepare for drag
            if !isDragging {
                isDragging = true
                HapticManager.shared.trigger(.medium)
            }

        case .second(true, let drag):
            // Dragging
            dragOffset = drag?.translation ?? .zero

            // Check collision at current position
            let newCollisionState = proposedHasCollision
            if newCollisionState != hasCollision {
                hasCollision = newCollisionState
                HapticManager.shared.trigger(hasCollision ? .warning : .selection)
            }

            // Haptic on grid snap
            let snappedTime = proposedTime
            if let lastSnap = lastSnapTime, snappedTime != lastSnap {
                HapticManager.shared.trigger(.selection)
            }
            lastSnapTime = snappedTime

        default:
            break
        }
    }

    @State private var lastSnapTime: Date?

    private func handleDragEnded(value: SequenceGesture<LongPressGesture, DragGesture>.Value) {
        isDragging = false
        lastSnapTime = nil

        // Check if dropping on collision
        if hasCollision {
            // Bounce back to original position
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                dragOffset = .zero
                hasCollision = false
                showBounceAnimation = true
            }
            HapticManager.shared.trigger(.error)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showBounceAnimation = false
            }
        } else {
            // Valid drop - update task
            let snappedTime = proposedTime
            task.scheduleAt(time: snappedTime)
            try? modelContext.save()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                dragOffset = .zero
            }
            HapticManager.shared.trigger(.success)
        }
    }

    // MARK: - Helper Methods

    private func snapToGrid(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0

        // Snap to nearest 15 minutes
        let roundedMinute = Int(round(Double(minute) / 15.0) * 15.0) % 60
        let hourAdjustment = minute >= 52 ? 1 : 0

        var snapped = components
        snapped.minute = roundedMinute
        if let currentHour = components.hour {
            snapped.hour = currentHour + hourAdjustment
        }

        return calendar.date(from: snapped) ?? date
    }
}

// MARK: - Preview

#Preview {
    let task = Task(
        title: "مراجعة المشروع",
        duration: 60,
        category: .work,
        notes: "مراجعة شاملة للكود"
    )
    task.scheduleAt(time: Date())

    return DraggableTaskView(
        task: task,
        hourHeight: 60,
        baseTime: Calendar.current.startOfDay(for: Date()),
        prayers: []
    )
    .environmentObject(ThemeManager())
    .frame(height: 300)
    .padding()
}
