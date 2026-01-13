# ميزان (Mizan) - iOS Daily Planner with Prayer Integration

**خطط يومك حول ما يهم حقًا**
*Plan your day around what truly matters*

---

## 📱 Overview

Mizan is an Arabic-first daily planning app designed specifically for Muslims. It helps you organize your day around prayer times and achieve balance between your worldly tasks and worship.

### ✨ Key Features

- 🕌 **Accurate Prayer Times** - 8 calculation methods with automatic location detection
- 📅 **Interactive Timeline** - Visual hour-by-hour schedule with prayer blocks
- ✋ **Drag & Drop** - Intuitive task scheduling with collision detection
- 🔔 **Smart Notifications** - Prayer reminders with adhan audio
- 🎨 **Beautiful Themes** - 5 carefully designed themes (1 free, 4 Pro)
- 🌙 **Nawafil Support** - Voluntary prayers (Pro feature)
- 🔁 **Recurring Tasks** - Repeat daily/weekly/monthly (Pro feature)
- 📴 **Offline-First** - 30-day cache, works without internet

---

## 🏗️ Architecture

### Tech Stack
- **SwiftUI** - Modern declarative UI
- **SwiftData** - Local persistence
- **Combine** - Reactive state management
- **CoreLocation** - GPS for prayer calculations
- **UserNotifications** - Prayer & task reminders
- **Aladhan API** - Prayer times data source

### Project Structure
```
Mizan/
├── App/                    # App entry point, DI container
├── Core/
│   ├── Configuration/      # JSON config loader
│   ├── Models/            # SwiftData models
│   ├── Network/           # API client, caching
│   ├── Services/          # Business logic services
│   └── Utilities/         # Extensions, helpers
├── Features/
│   ├── Timeline/          # Main timeline view
│   ├── TaskManagement/    # Inbox, add/edit tasks
│   ├── Prayer/            # Prayer settings
│   ├── Settings/          # App preferences
│   └── Onboarding/        # 4-step wizard
├── DesignSystem/          # Themes, typography, components
└── Resources/
    ├── Configuration/     # 6 JSON config files
    └── Assets.xcassets/   # Images, colors
```

---

## 🚀 Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+
- macOS Sonoma+

### Build & Run

1. Open `Mizan.xcodeproj` in Xcode
2. Select a simulator (iPhone 15 Pro recommended)
3. Press **⌘ + R** to build and run

### First Launch

The app will guide you through:
1. **Welcome** - App introduction
2. **Location** - Permission for prayer calculations
3. **Calculation Method** - Choose from 8 methods
4. **Notifications** - Enable prayer & task reminders

---

## 📊 Statistics

- **27 Swift files** (~10,000+ lines)
- **6 JSON configuration files**
- **Zero hardcoded values** - Fully configuration-driven
- **8 calculation methods** - MWL, ISNA, Egypt, Makkah, Karachi, Tehran, Jafari, Gulf
- **5 prayer times** - Fajr, Dhuhr, Asr, Maghrib, Isha
- **9 nawafil types** - Sunnah prayers and voluntary worship
- **6 task categories** - Work, Personal, Study, Health, Social, Worship

---

## 🎨 Themes

1. **Noor** (Light) - FREE
2. **Layl** (OLED Dark) - Pro
3. **Fajr** (Dawn Gradient) - Pro
4. **Sahara** (Desert Warm) - Pro
5. **Ramadan** (Festive) - Pro (auto-activates during Ramadan)

---

## 🔧 Configuration System

All app behavior is controlled via JSON files in `Resources/Configuration/`:

- **PrayerConfig.json** - Prayer durations, buffers, colors, API settings
- **ThemeConfig.json** - 5 complete themes with colors, fonts, shadows
- **AnimationConfig.json** - Spring physics, haptics, animation curves
- **NawafilConfig.json** - 9 voluntary prayer types with scheduling rules
- **NotificationConfig.json** - All notification templates and timings
- **LocalizationConfig.json** - Arabic (primary) and English strings

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] Onboarding completes successfully
- [ ] Location permission granted
- [ ] Prayer times load and display
- [ ] Create task in inbox
- [ ] Drag task to timeline
- [ ] Task collision detection works (red border on prayer overlap)
- [ ] Theme switching works
- [ ] Notifications scheduled

### Test Locations

Use these coordinates for testing:
- **Riyadh, Saudi Arabia**: 24.7136, 46.6753 (Umm Al-Qura method)
- **Dubai, UAE**: 25.2048, 55.2708 (Gulf method)
- **Cairo, Egypt**: 30.0444, 31.2357 (Egyptian method)
- **New York, USA**: 40.7128, -74.0060 (ISNA method)

---

## 🏆 Pro Features

**Mizan Pro** unlocks:
- ✨ 4 premium themes
- 🌙 Nawafil prayers (9 types)
- 🔁 Recurring tasks
- ⏰ Advanced notifications (before/after reminders)
- 📆 Calendar sync (future)
- 🎵 Custom adhan audio (future)
- 📊 Week view (future)

---

## 📖 API Documentation

### Aladhan Prayer Times API

**Endpoint**: `https://api.aladhan.com/v1/timings`

**Parameters**:
- `date`: YYYY-MM-DD
- `latitude`: Decimal degrees
- `longitude`: Decimal degrees
- `method`: 1-13 (calculation method)
- `school`: 0 (Shafi) or 1 (Hanafi)

**Response**: JSON with prayer times, Hijri date, and metadata

---

## 📝 License

Copyright © 2024 Mizan. All rights reserved.

---

## 🙏 Acknowledgments

- **Aladhan API** - Prayer times data (https://aladhan.com)
- **Islamic Finder** - Calculation methods reference
- **Muslim Pro** - Design inspiration

---

## 📧 Contact

- **Issues**: Report bugs via GitHub Issues
- **Support**: [Email support]
- **Docs**: See `Docs/Mizan Full PRD.md` for complete specification

---

**Built with ❤️ for the Muslim community**

الحمد لله
