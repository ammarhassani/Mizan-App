# Mizan Project Guidelines for Claude

This document contains mandatory coding guidelines that Claude MUST follow when working on this project.

## Theme System - MANDATORY

Mizan uses a comprehensive theme system managed by `ThemeManager`. **All UI components MUST be theme-aware.**

### Core Principle

**NEVER use hardcoded colors.** Always use `themeManager` color properties.

### Required Setup for Views

Every SwiftUI view that displays colors MUST have access to the ThemeManager:

```swift
struct MyView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        // Use themeManager colors here
    }
}
```

### Available Theme Colors

Use ONLY these color accessors from `themeManager`:

| Property | Usage |
|----------|-------|
| `primaryColor` | Main accent color, buttons, highlights |
| `backgroundColor` | Main background |
| `surfaceColor` | Cards, sheets, elevated surfaces |
| `surfaceSecondaryColor` | Secondary surface elements |
| `textPrimaryColor` | Primary text |
| `textSecondaryColor` | Secondary/muted text |
| `textTertiaryColor` | Tertiary/disabled text |
| `textOnPrimaryColor` | Text on primaryColor backgrounds |
| `successColor` | Success states, checkmarks |
| `errorColor` | Error states, delete actions |
| `warningColor` | Warning states, Pro badges |

### Forbidden Patterns

**DO NOT USE:**
```swift
// BAD - Hardcoded colors
.foregroundColor(.white)
.foregroundColor(.red)
.foregroundColor(.green)
.foregroundColor(.secondary)
.fill(Color.white)
.fill(Color.gray)
Color(hex: "#14746F")  // Hardcoded hex
Color(hex: "#FFD700")  // Hardcoded hex
```

**INSTEAD USE:**
```swift
// GOOD - Theme-aware colors
.foregroundColor(themeManager.textOnPrimaryColor)
.foregroundColor(themeManager.errorColor)
.foregroundColor(themeManager.successColor)
.foregroundColor(themeManager.textSecondaryColor)
.fill(themeManager.surfaceColor)
.fill(themeManager.textSecondaryColor.opacity(0.3))
themeManager.primaryColor
themeManager.warningColor
```

### Common Patterns

#### Buttons on Primary Background
```swift
Button {
    action()
} label: {
    Text("Save")
        .foregroundColor(themeManager.textOnPrimaryColor)  // NOT .white
        .background(themeManager.primaryColor)
}
```

#### Selected State Chips
```swift
.foregroundColor(isSelected ? themeManager.textOnPrimaryColor : themeManager.textPrimaryColor)
.background(isSelected ? themeManager.primaryColor : themeManager.surfaceSecondaryColor)
```

#### Delete/Destructive Actions
```swift
.foregroundColor(themeManager.errorColor)  // NOT .red
```

#### Success/Checkmarks
```swift
.foregroundColor(themeManager.successColor)  // NOT .green
```

#### Pro Badges
```swift
.foregroundColor(themeManager.textPrimaryColor)
.background(themeManager.warningColor)  // NOT Color(hex: "#FFD700")
```

#### Disabled States
```swift
.fill(themeManager.textSecondaryColor.opacity(0.5))  // NOT Color.gray
```

### Views on Primary/Gradient Backgrounds

For views displayed on top of `primaryColor` gradients (like onboarding, paywalls):

```swift
// Use textOnPrimaryColor for all text and icons
Text("Title")
    .foregroundColor(themeManager.textOnPrimaryColor)

Circle()
    .fill(themeManager.textOnPrimaryColor.opacity(0.2))

// For the background itself, use primaryColor gradient
LinearGradient(
    colors: [themeManager.primaryColor, themeManager.primaryColor.opacity(0.7)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Form and List Backgrounds - CRITICAL

SwiftUI `Form` and `List` views use system default backgrounds that DO NOT adapt to themes. **You MUST add these modifiers to every Form and List:**

```swift
Form {
    // Form content
}
.scrollContentBackground(.hidden)  // Hide system background
.background(themeManager.backgroundColor.ignoresSafeArea())  // Apply theme background
.navigationTitle("Title")
```

**Without these modifiers, the screen will show a black/system background instead of the theme background.**

Same applies to `List`:
```swift
List {
    // List content
}
.scrollContentBackground(.hidden)
.background(themeManager.backgroundColor.ignoresSafeArea())
```

### View Backgrounds

All views that serve as pages/screens should have proper theme backgrounds:

```swift
var body: some View {
    ZStack {
        themeManager.backgroundColor
            .ignoresSafeArea()

        // View content
    }
}
```

Or for ScrollView-based layouts:
```swift
ScrollView {
    // Content
}
.background(themeManager.backgroundColor.ignoresSafeArea())
```

### Component Checklist

Before submitting any code, verify:

- [ ] View has `@EnvironmentObject var themeManager: ThemeManager`
- [ ] No hardcoded `.white`, `.black`, `.red`, `.green`, `.gray`, `.secondary`
- [ ] No hardcoded hex colors like `Color(hex: "#...")`
- [ ] Button text on primary backgrounds uses `textOnPrimaryColor`
- [ ] Selected states use `textOnPrimaryColor` on `primaryColor` background
- [ ] Error states use `errorColor`
- [ ] Success states use `successColor`
- [ ] Pro/Premium badges use `warningColor`
- [ ] Forms and Lists have `.scrollContentBackground(.hidden)` and `.background(themeManager.backgroundColor.ignoresSafeArea())`
- [ ] Page/screen views have proper theme background (ZStack with backgroundColor or .background modifier)

### Typography

Use the `MZTypography` system for fonts:

```swift
.font(MZTypography.headlineLarge)
.font(MZTypography.titleMedium)
.font(MZTypography.bodyLarge)
.font(MZTypography.labelMedium)
```

### Spacing

Use the `MZSpacing` system:

```swift
.padding(MZSpacing.md)
.padding(.horizontal, MZSpacing.screenPadding)
VStack(spacing: MZSpacing.sm) { }
```

### Corner Radius

Use theme-based corner radius:

```swift
.cornerRadius(themeManager.cornerRadius(.medium))
.cornerRadius(themeManager.cornerRadius(.large))
```

## Summary

The theme system is critical for user experience. Users can select from multiple themes (Noor, Layl, Fajr, Sahara, Ramadan), and **every screen must adapt** to the selected theme. Hardcoded colors break this experience.

When in doubt, ask: "Will this color change when the user switches themes?" If yes, use `themeManager`.
