# 📿 Mizan - Complete Product Requirements Document
**Version:** 1.0  
**Last Updated:** January 13, 2026  
**Project Type:** iOS Daily Planner with Prayer Integration  
**Development Approach:** Vibe Coding with Claude Code + DeepSeek API  

---

## 🚨 Critical Development Notes

### For Claude Code / Opus:
1. **No Code Provided**: This PRD intentionally contains NO code snippets. All implementation details are marked as `[Implementation details removed - Opus will design architecture]`. You must think through and design the architecture yourself - do not expect ready-made code.

2. **Configuration-Driven**: Everything must be driven by JSON configuration files (see Configuration section). NO hardcoded values for colors, timings, strings, or settings.

3. **Arabic-First Interface**: Primary language is Arabic (RTL layout). English is secondary and added later via settings. All UI text, prayer names, and default content must be in Arabic.

4. **WOW UI Focus**: This is not a generic planner. Every animation, transition, and interaction must be **exceptional**. Study the design philosophy section carefully - 60 FPS animations, spring physics, haptic feedback, and attention-grabbing details are mandatory.

5. **DeepSeek API Usage**: Available for smart rescheduling feature (v2.0). Use for AI-powered task organization, not for basic scheduling logic.

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Product Vision](#product-vision)
3. [Target Users & Personas](#target-users--personas)
4. [Core Features Specification](#core-features-specification)
5. [UI/UX Design System](#uiux-design-system)
   - Design Philosophy: The WOW Factor
   - Next-Gen Animation Strategy
   - Theme System (5 Unique Designs)
   - Typography (Arabic-First)
   - Spacing & Layout
   - Micro-Interactions
6. [Localization & Configuration](#localization--configuration)
   - Arabic Primary Language
   - Configuration-Driven Architecture
7. [Technical Architecture](#technical-architecture)
   - Performance Requirements
8. [Notifications System](#notifications-system)
9. [Nawafil Prayers (Pro Feature)](#nawafil-prayers-pro-feature)
   - Accurate Islamic Specifications
   - 9 Nawafil Types
   - Sunnah Rawatib Auto-Configuration
10. [Special Prayers & Adaptive Calendar](#special-prayers--adaptive-calendar)
    - Jummah (Friday) Prayer
    - Ramadan Mode (Automatic)
    - Eid Prayers
11. [Business Model & Pricing](#business-model--pricing)
    - Pro Upgrade Flow
12. [Development Roadmap](#development-roadmap)
13. [API Integration](#api-integration)
    - Prayer Calculation Methods
    - Error Handling Specifications
14. [User Experience](#user-experience)
    - Onboarding Flow Details
    - Competitive Differentiation
15. [Testing Strategy](#testing-strategy)

---

## Executive Summary

### Product Name
**Mizan** (ميزان) - "The Balance"

### Tagline
"Plan your day around what matters most"

### The Problem
Muslims who use productivity apps face a fundamental conflict:
- **Prayer time apps** (Muslim Pro, Athan): Remind you to pray but don't help organize your day
- **Productivity apps** (Structured, Todoist): Help you plan but completely ignore prayer times
- **Result**: Users manually block prayer times, feel guilty when tasks overlap with salah, or simply give up on structured planning

### The Solution
Mizan is a daily planner where **prayer times are anchors** - fixed, immovable blocks that automatically organize your day. All tasks flow around salah, never through it.

### Unique Value Proposition
1. **Prayer-First Planning**: Only app that treats prayer as scheduling infrastructure, not an afterthought
2. **No Guilt, Just Structure**: Doesn't track if you prayed, just makes it harder to schedule over prayer
3. **Smart Rescheduling**: When tasks run late, automatically reorganizes remaining schedule while preserving prayer times
4. **Beautiful & Modern**: Clean Islamic aesthetics without being preachy

### Market Validation
- **Muslim Pro**: 150M+ downloads, proves demand for Islamic apps
- **Structured**: 1M+ users at $29.99, proves time-blocking market
- **Gap**: No app combines both successfully
- **Target**: 50K users Year 1, 5-10% Pro conversion = $140K-600K revenue

---

## Product Vision

### Mission Statement
Empower Muslims to live productive, balanced lives where faith and ambition coexist naturally through intelligent time management.

### Core Principles
1. **Respect**: Never guilt-trip, track, or judge prayer habits
2. **Simplicity**: One thing done exceptionally well (daily planning)
3. **Privacy**: Local-first, no account required, data stays on device
4. **Beauty**: Modern Islamic design that feels premium and intentional
5. **Inclusivity**: Works for strict observers and casual Muslims alike

### What Mizan IS
- ✅ A daily planner that respects prayer
- ✅ A productivity tool with Islamic awareness
- ✅ A scheduling assistant that prevents conflicts

### What Mizan IS NOT
- ❌ A prayer tracking app (no guilt metrics)
- ❌ An Islamic education platform (no Quran, hadith, dua collections)
- ❌ A social network (no sharing, no community features)
- ❌ A habit tracker (separate concern, maybe future integration)

---

## Target Users & Personas

### Primary Demographic
- **Age**: 18-35 years old
- **Geography**: 
  - **Phase 1**: Saudi Arabia, UAE, Kuwait (GCC markets)
  - **Phase 2**: USA, UK, Canada, Western markets
  - **Phase 3**: Indonesia, Malaysia, Pakistan (mass market)
- **Tech Profile**: 
  - iPhone users
  - Already using productivity apps (Notion, Todoist, Structured)
  - Comfortable with paid apps ($3-10/month range)
- **Faith Profile**:
  - Prays 5 times daily (or seriously trying to)
  - Values Islamic principles but not rigidly traditional
  - Struggles to balance deen and dunya

### User Personas

#### Persona 1: **Ahmed - Engineering Student**
[Implementation details removed - Opus will design architecture]

#### Persona 2: **Sarah - Marketing Manager**
[Implementation details removed - Opus will design architecture]

#### Persona 3: **Youssef - Freelance Designer**
[Implementation details removed - Opus will design architecture]

### Secondary Personas

**Fatima - Stay-at-Home Mom** (28, homeschooling, needs flexible scheduling)  
**Omar - University Professor** (45, rigid class schedule, values punctuality)  
**Layla - Medical Resident** (26, unpredictable shifts, needs mobile-first solution)

---

## Core Features Specification

### Feature Overview Table

| Feature | Priority | Version | Free | Pro |
|---------|----------|---------|------|-----|
| Automatic Prayer Times | P0 | v1.0 | ✅ | ✅ |
| Visual Timeline Planner | P0 | v1.0 | ✅ | ✅ |
| Task Management (Inbox) | P0 | v1.0 | ✅ | ✅ |
| Drag & Drop Scheduling | P0 | v1.0 | ✅ | ✅ |
| Basic Task Notifications | P0 | v1.0 | ✅ | ✅ |
| Prayer Notifications | P0 | v1.0 | ✅ | ✅ |
| 3 Task Categories | P0 | v1.0 | ✅ | ✅ |
| Dark Mode | P0 | v1.0 | ✅ | ✅ |
| Recurring Tasks | P1 | v1.0 | ❌ | ✅ |
| Advanced Notifications | P1 | v1.0 | ❌ | ✅ |
| Calendar Sync | P1 | v1.0 | ❌ | ✅ |
| Custom Prayer Durations | P1 | v1.0 | ❌ | ✅ |
| Multiple Adhan Audio | P1 | v1.0 | ❌ | ✅ |
| Nawafil Prayer Tracking | P1 | v1.0 | ❌ | ✅ |
| Widgets (3 sizes) | P2 | v1.1 | ❌ | ✅ |
| Week View | P2 | v1.1 | ❌ | ✅ |
| Apple Watch App | P2 | v1.5 | ❌ | ✅ |
| AI Smart Rescheduling | P2 | v2.0 | ❌ | ✅ |
| Cloud Sync | P2 | v2.0 | ❌ | ✅ |

**Priority Levels:**
- **P0**: Must-have for MVP, app doesn't work without it
- **P1**: Should-have for MVP, significantly improves experience
- **P2**: Nice-to-have, can wait for post-launch iterations

---

## Feature 1: Automatic Prayer Times Integration ⭐ P0

### Overview
Automatically fetches and displays accurate prayer times as fixed, immovable blocks in the timeline based on user's location.

### User Stories
- **As a Muslim user**, I want prayer times to automatically appear in my daily schedule so I don't have to manually add them
- **As a traveler**, I want prayer times to update automatically when I change locations
- **As someone who follows a specific calculation method**, I want to choose my preferred method (Umm al-Qura, ISNA, etc.)

### Technical Specifications

#### API Integration
[Implementation details removed - Opus will design architecture]

#### Location Services
[Implementation details removed - Opus will design architecture]

#### Prayer Time Caching
[Implementation details removed - Opus will design architecture]

#### Prayer Time Rendering
[Implementation details removed - Opus will design architecture]

### Prayer Duration & Buffer Configuration

#### Default Durations (minutes)
[Implementation details removed - Opus will design architecture]

### Collision Detection Algorithm
[Implementation details removed - Opus will design architecture]

### User Settings
[Implementation details removed - Opus will design architecture]

### Acceptance Criteria
- [ ] Prayer times appear automatically on timeline for current day
- [ ] Times update when user's location changes > 50km
- [ ] Calculation method can be changed in settings
- [ ] Prayer blocks cannot be dragged, deleted, or modified
- [ ] Prayer blocks have distinct visual styling (green gradient)
- [ ] Buffer times prevent task scheduling immediately before/after prayer
- [ ] Offline mode: Shows cached prayer times for next 30 days
- [ ] Prayer times for next day are fetched at midnight automatically

---

## Feature 2: Visual Timeline Planner ⭐ P0

### Overview
Day view timeline from Fajr to midnight with drag-and-drop task scheduling. Think Google Calendar meets Structured, with prayer times as immovable anchors.

### User Stories
- **As a user**, I want to see my entire day at a glance on a vertical timeline
- **As someone with tasks**, I want to drag tasks from inbox onto timeline and see them scheduled
- **As a planner**, I want visual feedback when tasks would conflict with prayer times

### UI Layout Specification

#### Timeline Structure
[Implementation details removed - Opus will design architecture]

#### SwiftUI Implementation
[Implementation details removed - Opus will design architecture]

#### Drag & Drop Interaction
[Implementation details removed - Opus will design architecture]

#### Time Grid Snapping
[Implementation details removed - Opus will design architecture]

### Timeline Features

#### Current Time Indicator
[Implementation details removed - Opus will design architecture]

#### Empty State (No tasks scheduled)
[Implementation details removed - Opus will design architecture]

### Acceptance Criteria
- [ ] Timeline displays from Fajr time to midnight
- [ ] Hour markers at every hour, half-hour lines at 30-min intervals
- [ ] Current time indicator updates every minute
- [ ] Drag-and-drop works smoothly (60 FPS)
- [ ] Tasks snap to 15-minute grid
- [ ] Prayer blocks cannot be dragged
- [ ] Collision detection prevents overlapping prayer
- [ ] Scroll automatically to current time on load
- [ ] Zoom in/out with pinch gesture
- [ ] Empty state when no tasks scheduled

---

## Feature 3: Task Management & Inbox System ⭐ P0

### Overview
Capture tasks quickly in an inbox, then drag them onto the timeline when ready to schedule. Supports categories, durations, notes, and completion tracking.

### User Stories
- **As a busy user**, I want to quickly capture task ideas without scheduling them immediately
- **As an organizer**, I want to categorize tasks by type (Work, Personal, Study, etc.)
- **As a realistic planner**, I want to estimate how long tasks will take

### Data Model
[Implementation details removed - Opus will design architecture]

### Inbox UI
[Implementation details removed - Opus will design architecture]

### Add/Edit Task Sheet
[Implementation details removed - Opus will design architecture]

### Quick Add (Floating Action Button)
[Implementation details removed - Opus will design architecture]

### Recurring Tasks (Pro Feature)
[Implementation details removed - Opus will design architecture]

### Acceptance Criteria
- [ ] Tasks can be created via Inbox or quick-add button
- [ ] Title is required, other fields optional
- [ ] Duration selector: 15, 30, 45, 60, 90, 120, 180, 240 minutes
- [ ] 6 categories with distinct colors and icons
- [ ] Notes field supports up to 500 characters
- [ ] Swipe right to schedule, swipe left to delete
- [ ] Recurring tasks require Pro (show paywall)
- [ ] Task count badge on inbox button
- [ ] Tasks persist across app restarts (SwiftData)
- [ ] Fast: Create task in < 5 seconds

---

## Feature 8: Local Notifications System ⭐ P0 & P1

### Overview
Comprehensive notification system for both prayer times and tasks. Supports pre-task reminders, start notifications, and post-task reminders (Pro feature).

### User Stories
- **As a user**, I want to be reminded 10 minutes before each prayer so I can wrap up work
- **As a task manager**, I want notifications when tasks are about to start
- **As someone who runs late** (Pro), I want reminders after task end time if I'm still working

### Notification Types

#### 1. Prayer Notifications (All Users)
[Implementation details removed - Opus will design architecture]

#### 2. Task Notifications

**Free Users:**
- ✅ Notify at task start time
- ✅ Basic notification sound

**Pro Users:**
- ✅ Notify X minutes before task starts (customizable: 5, 10, 15, 30 min)
- ✅ Notify at task start time
- ✅ Notify Y minutes after task should have ended (if not completed)
- ✅ Custom notification sounds per category
- ✅ Smart snooze (5, 10, 15 min intervals)

[Implementation details removed - Opus will design architecture]

### Implementation

#### Notification Manager
[Implementation details removed - Opus will design architecture]

#### Notification Settings UI
[Implementation details removed - Opus will design architecture]

### Notification Permissions Flow
[Implementation details removed - Opus will design architecture]

### Acceptance Criteria
- [ ] Permission request during onboarding
- [ ] Prayer notifications: 10 min before, at time (with adhan), 5 min after
- [ ] Task notifications: At start time (free), before/after (Pro)
- [ ] Notification actions: Complete, Snooze, Extend
- [ ] Settings to enable/disable per type
- [ ] Adhan audio selection (5+ options)
- [ ] Works when app is in background
- [ ] Notifications respect Do Not Disturb mode
- [ ] Badge count shows pending tasks
- [ ] Rich notifications with category icons

---

## Feature 9: Nawafil Prayers (Pro Feature) ⭐ P1

### Overview
Optional tracking and scheduling of voluntary (sunnah/nawafil) prayers alongside obligatory prayers. Pro-only feature to monetize devout users who want comprehensive Islamic practice integration.

### User Stories
- **As a practicing Muslim** (Pro), I want to schedule Sunnah prayers (Duha, Tahajjud, Witr) in my timeline
- **As someone trying to improve** (Pro), I want gentle reminders for voluntary prayers without guilt
- **As a planner** (Pro), I want nawafil to be suggested but not mandatory like obligatory prayers

### Nawafil Types Supported (Accurate Islamic Specifications)

#### 1. **Before Fajr (Sunnah Mu'akkadah)**
- **Rakaat**: 2 (fixed)
- **Timing**: After Adhan, before Fajr prayer
- **Duration Default**: 10 minutes
- **Auto-schedule**: Appears automatically 15 minutes before Fajr time
- **Arabic Name**: ركعتا الفجر
- **Importance**: Highly emphasized sunnah

#### 2. **Salat al-Duha (Forenoon Prayer)**
- **Rakaat**: 2-12 (user configurable, always even number)
- **Timing**: From 15 minutes after sunrise until 10 minutes before Dhuhr
- **Optimal Time**: Mid-morning (around 9:00 AM)
- **Duration**: Calculated based on user-selected rakaat (5 min per 2 rakaat)
- **Arabic Name**: صلاة الضحى
- **User Choice**: Slider in settings (2, 4, 6, 8, 10, 12 rakaat options)

#### 3. **Before Dhuhr (Sunnah Rawatib)**
- **Rakaat**: 4 (fixed)
- **Timing**: After Adhan, before Dhuhr prayer
- **Duration Default**: 15 minutes
- **Auto-schedule**: Appears 20 minutes before Dhuhr if enabled
- **Arabic Name**: أربع ركعات قبل الظهر

#### 4. **After Dhuhr (Sunnah Rawatib)**
- **Rakaat**: 2 (fixed)
- **Timing**: Immediately after Dhuhr prayer
- **Duration Default**: 10 minutes
- **Auto-schedule**: Appears right after Dhuhr block if enabled
- **Arabic Name**: ركعتان بعد الظهر

#### 5. **Asr - No Nawafil**
- **Note**: No regular sunnah prayers associated with Asr
- Rawatib toggle does not affect Asr

#### 6. **After Maghrib (Sunnah Rawatib)**
- **Rakaat**: 2 (fixed)
- **Timing**: Immediately after Maghrib prayer
- **Duration Default**: 10 minutes
- **Auto-schedule**: Appears right after Maghrib block if enabled
- **Arabic Name**: ركعتان بعد المغرب

#### 7. **After Isha (Sunnah Rawatib)**
- **Rakaat**: 2 (fixed)
- **Timing**: Immediately after Isha prayer
- **Duration Default**: 10 minutes
- **Auto-schedule**: Appears right after Isha block if enabled
- **Arabic Name**: ركعتان بعد العشاء

#### 8. **Witr Prayer (Mandatory End to Night)**
- **Rakaat**: 1, 3, 5, 7, 9, or 11 (user configurable, must be odd)
- **Timing**: After Isha, before Fajr (typically last prayer of the night)
- **Optimal Time**: After Tahajjud if user prays it, otherwise before sleeping
- **Duration**: Calculated based on user-selected rakaat (7 min per 1 rakaat, 10 min per 3, etc.)
- **Arabic Name**: صلاة الوتر
- **User Choice**: Picker in settings (1, 3, 5, 7, 9, 11 rakaat options)
- **Importance**: Highly emphasized, considered mandatory by some scholars

#### 9. **Qiyam al-Layl (Night Vigil) - Special Type**
- **NOT a specific prayer**: This is a **time block** for spiritual activities
- **Rakaat**: Variable - user prays as many as they wish
- **Timing**: Last third of the night (calculated dynamically based on Maghrib to Fajr span)
- **Default Block Duration**: 60 minutes (user customizable: 30, 60, 90, 120 minutes)
- **Activities**: Prayer, Quran recitation, dhikr, dua - whatever the user chooses
- **Arabic Name**: قيام الليل
- **Display**: Special icon (🌙✨) and message "Best time for worship - pray, read Quran, make dua"
- **Flexibility**: Not marked as "complete/incomplete" - just a reminder block
- **Ramadan Note**: Especially emphasized during Ramadan

### Sunnah Rawatib Auto-Configuration

**When User Enables "Sunnah Rawatib"**:
- **Option 1**: Enable all rawatib prayers (before Fajr, before/after Dhuhr, after Maghrib, after Isha)
- **Option 2**: Granular control - toggle each one individually in Pro settings

**Smart Scheduling**:
- Before prayers: Scheduled with enough buffer to complete before obligatory prayer
- After prayers: Scheduled immediately after obligatory prayer block ends
- Visual distinction: Lighter shade, "نافلة" badge, optional completion checkmark

### Configuration-Driven Nawafil

All nawafil specifications live in **NawafilConfig.json**:
- Rakaat options for each type
- Default durations
- Timing rules
- Arabic/English names
- Emoji representations
- Auto-schedule logic
- Rawatib attachment rules

Example structure:
[Implementation details removed - Opus will design architecture]

### Special Nawafil Display

**Timeline Rendering**:
- **Fard Prayers**: Solid green gradient, bold text, immovable
- **Nawafil Prayers**: Translucent green, lighter font, "نافلة" badge
- **Qiyam al-Layl**: Purple gradient with moon/stars, inspirational text

**User Interaction**:
- Nawafil can be temporarily dismissed for a day ("Skip today")
- Completion tracking is optional (toggle in settings)
- No guilt messaging - purely supportive
- Statistics show personal trends, not judgments

---

## Special Prayers & Adaptive Calendar

### Friday (Jummah) Prayer Adaptation

**Automatic Detection**:
- App recognizes Friday based on device calendar
- Dhuhr prayer is **replaced** with Jummah prayer on Fridays

**Jummah Prayer Specifications**:
- **Timing**: Typically 30 minutes after Dhuhr adhan (configurable in settings)
- **Duration**: 60 minutes (includes khutbah + prayer)
- **Buffer Before**: 15 minutes (recommended early arrival)
- **Buffer After**: 5 minutes
- **Arabic Name**: صلاة الجمعة
- **Special Icon**: 🕌 Mosque icon
- **Color**: Distinct gold-green gradient
- **Notification**: "Jummah in 30 minutes - don't forget!"

**User Options**:
- Set custom Jummah time (if mosque schedule differs from Dhuhr)
- Toggle "Remind me 1 hour before" for travel time
- Option to add "Travel to mosque" task auto-scheduled before Jummah

**Timeline Behavior**:
- Tasks automatically rescheduled around longer Jummah block
- Lunch break suggestions appear after Jummah

### Ramadan Mode (Automatic Activation)

**Trigger**: Activates automatically based on Hijri calendar (detected from PrayerTimes API)

**Ramadan-Specific Features**:

1. **Suhoor (Pre-Dawn Meal) Block**
   - Auto-scheduled 30-45 minutes before Fajr
   - Duration: 30 minutes (customizable)
   - Notification: "Wake up for Suhoor - Fajr in 1 hour"
   - Icon: 🍽️

2. **Iftar (Breaking Fast) Block**
   - Auto-scheduled at exact Maghrib time
   - Duration: 15 minutes (just for breaking fast, not full dinner)
   - Notification: "It's time to break your fast! 🌙"
   - Icon: 🥤

3. **Tarawih Prayer**
   - Auto-scheduled after Isha every night of Ramadan
   - Rakaat: Typically 8 or 20 (user selectable in Ramadan settings)
   - Duration: 45-60 minutes (based on rakaat count)
   - Timing: 15-30 minutes after Isha
   - Arabic Name**: صلاة التراويح
   - Special Icon: 🕌✨
   - Mosque option: Toggle "I pray Tarawih at mosque" to block longer time

4. **Tahajjud (Emphasized in Ramadan)**
   - Same as Qiyam al-Layl but more prominently suggested
   - Default duration increased to 90 minutes during Ramadan
   - Special Ramadan notification: "Last 10 nights - best time for Laylat al-Qadr"

5. **Theme Auto-Switch**
   - "Ramadan" theme activates automatically (Pro feature)
   - User can opt-out and keep preferred theme

6. **Last 10 Nights Emphasis**
   - Extra notifications and encouragement for Qiyam/Tahajjud
   - Laylat al-Qadr suggestion on odd nights (21, 23, 25, 27, 29)

### Eid Prayers (Automatic Detection)

**Trigger**: Activates on Eid al-Fitr and Eid al-Adha based on confirmed dates in app configuration

**Eid Prayer Specifications**:
- **Timing**: Approximately 15-30 minutes after sunrise
- **Duration**: 45 minutes (prayer + khutbah)
- **Notification**: "Eid Mubarak! 🎉 Eid prayer in 1 hour"
- **Arabic Name**: صلاة العيد
- **Special Icon**: 🎊 or 🕌
- **Color**: Festive gradient (gold and green)

**Eid Day Adaptations**:
- No Duha prayer (replaced by Eid prayer)
- Fasting reminders disabled (Eid al-Fitr)
- Special "Eid Preparation" task suggestions (morning of Eid)
- Timeline shows festive confetti animation throughout the day
- Extended congratulatory message: "Eid Mubarak! May your day be filled with joy 🌙✨"

### Configuration for Special Prayers

**SpecialPrayersConfig.json**:
[Implementation details removed - Opus will design architecture]

### User Experience Notes

**Smart Defaults with User Control**:
- All special prayers have sensible defaults
- Pro users can customize every aspect
- Free users get automatic detection and scheduling

**Gentle Adaptation**:
- Special prayers appear seamlessly in timeline
- No overwhelming UI changes
- Subtle celebratory touches (animations, colors)
- Notifications are informative, not pushy

**Respect for Variation**:
- Settings acknowledge that practices vary by region and madhab
- Users can disable automatic Ramadan mode if they travel
- Eid dates can be manually adjusted if user follows different calendar authority



### UI Implementation

#### Nawafil Settings (Pro Only)
[Implementation details removed - Opus will design architecture]

#### Timeline Display (Nawafil vs Fard)
[Implementation details removed - Opus will design architecture]

### Nawafil Statistics (Optional - v2.0)
[Implementation details removed - Opus will design architecture]

### Paywall Integration
[Implementation details removed - Opus will design architecture]

### Acceptance Criteria
- [ ] Nawafil feature only visible to Pro users
- [ ] Free users see paywall when trying to access
- [ ] 5 nawafil types supported: Tahajjud, Duha, Witr, Rawatib (before/after)
- [ ] Each has default time and duration (customizable)
- [ ] Displayed differently from fard prayers (lighter color, "OPTIONAL" badge)
- [ ] Can be marked complete with checkmark (optional)
- [ ] Gentle notifications if enabled
- [ ] No guilt if skipped - purely supportive
- [ ] Completion history tracked but not judged
- [ ] Settings to enable/disable each type
- [ ] Rawatib auto-attached to fard prayers if enabled

---

## UI/UX Design System

### Design Philosophy: The WOW Factor

Mizan aims to be **the most beautiful Islamic productivity app ever built**. We're not just building a planner - we're creating an experience that users **desperately want** to open every day, an app so delightful that it becomes a joy, not a chore.

**Inspiration from Top-Rated Beautiful iOS Apps (2026):**

1. **Flighty**: Gold standard for sophisticated dark interfaces with real-time updates and high-quality haptics - smooth, professional, informative
2. **Things 3**: Minimalist, "paper-like" interface that feels deeply native to iPhone - every interaction feels intentional
3. **Bear Notes**: Elegant typography and clutter-free markdown environment - writing feels like a pleasure
4. **Crouton**: Clean, image-forward layout with playful interactive elements - fun without being childish
5. **Halide Camera**: Sleek, tactile interface with intuitive gestures - professional-grade feel
6. **Headspace**: Soft color palettes, friendly aesthetics, award-winning UI - calming and inviting

### Core Design Principles

1. **Prayer First, Beautifully**: Prayer times are not just functional - they're art. Rendered with gradients, shadows, and subtle animations
2. **Fluid Everything**: Every transition, every tap, every scroll should feel like water flowing - no jarring movements
3. **Delightful Surprises**: Hidden animations, easter eggs, thoughtful micro-interactions that make users smile
4. **Respectful Beauty**: Modern Islamic aesthetics (geometric patterns, arabesque motifs) without being preachy or traditional
5. **Performance = Beauty**: 60 FPS everywhere, instant feedback, zero lag. Beauty dies with stuttering animations
6. **Attention to Detail**: Pixel-perfect spacing, harmonious color relationships, typography that sings

### Next-Gen Animation Strategy

#### Animation Principles (Disney-inspired)
- **Squash & Stretch**: UI elements have weight and life
- **Anticipation**: Buttons press down before springing back
- **Staging**: Guide user attention through layered motion
- **Follow Through**: Elements settle naturally with spring physics
- **Slow In / Slow Out**: Easing functions that feel organic
- **Secondary Action**: Background elements react to foreground changes
- **Timing**: Fast actions complete in 0.2s, medium in 0.4s, slow in 0.6s

#### Signature Animations

**App Launch Sequence** (Total: 1.2s)
1. Splash screen fades out (0.3s)
2. Prayer countdown scales in with spring (0.4s) 
3. Timeline fades in with stagger effect (0.5s)
4. Haptic: Medium impact at peak of spring

**Task Creation Flow**
1. Plus button scales down (0.1s) → Haptic: Light
2. Sheet slides up from bottom with overshoot (0.4s spring)
3. Keyboard follows 0.1s after sheet
4. Title field pulses to draw attention (0.3s)
5. On save: Sheet slides down, new task flies to timeline position

**Drag & Drop Magic**
1. Long press (0.3s) triggers: Task lifts 8pt with shadow, slight scale (1.05x)
2. Haptic: Medium impact
3. Other timeline items gently shift to make space (0.3s spring)
4. Dragging over prayer block: Red glow pulses, task wobbles slightly
5. On drop: Task settles with spring physics, other items flow back
6. Haptic: Success or Warning based on validity

**Prayer Time Approach** (10 minutes before)
1. Prayer block begins subtle pulse (glow in/out, 3s cycle)
2. Countdown in header animates digits with flip effect
3. 5 minutes before: Pulse intensity increases
4. 1 minute before: Background subtly shifts to prayer gradient
5. At prayer time: Full-screen gentle expansion, adhan plays

**Task Completion**
1. Checkmark: Scale from 0 to 1.2x → spring back to 1.0x (0.4s)
2. Task: Fade out with scale down (0.3s)
3. Confetti burst (optional, Pro feature - 0.5s)
4. Haptic: Success notification
5. Next task highlights briefly to guide attention

**Theme Switch**
1. Current theme: Scale out with blur (0.3s)
2. Color wave transition across screen (0.5s)
3. New theme: Scale in with clarity (0.3s)
4. Haptic: Heavy impact at midpoint

#### Haptic Feedback Strategy

**Haptic Intensity Map**:
- **Light Impact**: Toggle switches, selecting items, scrolling snap points
- **Medium Impact**: Task creation, drag start, navigation transitions
- **Heavy Impact**: Prayer alert, collision detection, theme change
- **Success**: Task completion, prayer marked, settings saved
- **Warning**: Prayer conflict, validation error, unsaved changes
- **Error**: Failed action, network error, invalid input
- **Selection**: Time scrubbing, duration adjustment, category picker

**Haptic Timing Rules**:
- Synchronize with visual peak (not start)
- Multiple haptics must be 0.1s apart minimum
- Success haptic = action confirmation, not just visual candy

### Theme System: 5 Unique Designs

#### Theme Philosophy
Each theme is a **complete aesthetic experience** - not just color swaps. Typography, spacing, shadows, even animation curves can vary per theme.

#### Theme 1: **Default "Noor" (Light)** - FREE
- **Concept**: Pure, clean, paper-like (Things 3 inspired)
- **Primary Color**: Soft beige background (#F5F3EF)
- **Prayer Color**: Deep teal gradient (#14746F → #0E8F8B)
- **Text**: Near-black (#1A1A1A)
- **Shadows**: Subtle, soft
- **Feel**: Calm, minimal, professional
- **Font**: SF Pro Text (body), SF Pro Display (headers)

#### Theme 2: **"Layl" (Night)** - PRO
- **Concept**: OLED-optimized dark (Flighty inspired)
- **Primary Color**: True black (#000000)
- **Prayer Color**: Green-gold gradient (#52B788 → #D4A373)
- **Text**: Off-white (#E8E8E8)
- **Shadows**: Glows instead of shadows
- **Feel**: Premium, modern, sophisticated
- **Font**: SF Pro Rounded (body), SF Pro Display (headers)

#### Theme 3: **"Fajr" (Dawn)** - PRO
- **Concept**: Morning freshness, soft gradients
- **Primary Color**: Gradient sky (#E8DFF5 → #FCE1E4 → #FCF4DD)
- **Prayer Color**: Purple-blue gradient (#6C63FF → #5851DB)
- **Text**: Deep purple (#2D2A4A)
- **Shadows**: Colorful, layered (Crouton inspired)
- **Feel**: Energizing, optimistic, gentle
- **Font**: SF Pro Rounded (body), New York (headers - serif elegance)

#### Theme 4: **"Sahara" (Desert)** - PRO
- **Concept**: Earthy, warm, geometric patterns
- **Primary Color**: Sand beige (#E9D5C1)
- **Prayer Color**: Terracotta gradient (#D4734C → #C45A30)
- **Text**: Brown (#3D2817)
- **Shadows**: Hard shadows (Bear inspired)
- **Feel**: Grounded, traditional-modern fusion, warm
- **Font**: Avenir Next (body), SF Arabic Rounded (Arabic text)
- **Special**: Subtle arabesque pattern in backgrounds

#### Theme 5: **"Ramadan"** (Special Event) - PRO
- **Concept**: Celebration, joy, festive
- **Primary Color**: Deep purple (#1E1B4B) with golden accents
- **Prayer Color**: Gold gradient (#FFD700 → #FFA500)
- **Text**: White (#FFFFFF) with golden highlights
- **Shadows**: Glowing, festive
- **Feel**: Special, reverent, joyful
- **Font**: SF Pro Display (bold weights)
- **Special**: Crescent moon and star motifs, activated automatically during Ramadan

### Typography System

**Arabic-First Approach** (Default Language)
- **Primary Font**: SF Arabic Rounded (optimized for right-to-left)
- **Headers**: SF Arabic Display (Bold/Heavy)
- **Body**: SF Arabic Text (Regular/Medium)
- **Prayer Names**: Traditional Naskh (for authenticity)
- **Numbers**: Arabic-Indic numerals (١٢٣٤) with Latin option

**English Support** (Secondary, in Settings)
- **Primary Font**: SF Pro Text / SF Pro Rounded (based on theme)
- **Headers**: SF Pro Display / New York (based on theme)
- Activates when user switches language in settings

**Font Sizes** (Responsive)
- **Title**: 32pt (Arabic), 34pt (English)
- **Header**: 24pt
- **Body**: 17pt
- **Caption**: 13pt
- **Time**: 16pt (mono-spaced for consistency)

### Spacing & Layout

**Golden Ratio System** (1.618)
- Base unit: 8pt
- Small: 8pt
- Medium: 13pt (8 × 1.618)
- Large: 21pt (13 × 1.618)
- XLarge: 34pt (21 × 1.618)

**Safe Areas**
- Top: 60pt (header + countdown)
- Bottom: 90pt (toolbar + home indicator)
- Horizontal: 20pt padding

**Timeline Spacing**
- Hour height: 60pt (1 hour)
- 15-minute grid: 15pt
- Task minimum height: 30pt (30 min)

### Micro-Interactions Catalog

**Button States**
- Rest: 100% opacity, no transform
- Hover: N/A (touch interface)
- Press: 95% scale, 80% opacity, slight vertical shift (-2pt)
- Release: Spring back to rest (0.2s)

**Switches & Toggles**
- Toggle on: Slide knob right, background color transition (0.3s)
- Toggle off: Slide knob left, background fade (0.3s)
- Haptic: Light impact at toggle point

**Loading States**
- Spinner: Continuous rotation with spring-based pause/resume
- Skeleton screens: Shimmer effect (1.5s loop)
- Progress bars: Smooth fill with spring at milestones

**Empty States**
- Icon: Scale in with bounce (0.5s)
- Text: Fade in with slide up (0.4s, staggered)
- Button: Appear last with gentle pop (0.3s)

---

## Localization & Configuration

### Language Support

**Primary Language: Arabic** (Right-to-Left)
- All UI text in Modern Standard Arabic
- Prayer names in traditional Arabic calligraphy
- Full RTL layout support
- Arabic numerals as default (Western numerals in settings)

**Secondary Language: English** (Added in v1.1)
- Activated via Settings > Language
- Full app translation
- Maintains theme visual consistency
- Requires app restart to apply

### Configuration-Driven Architecture

**Core Principle**: No hardcoded values. Everything comes from configuration files.

#### Configuration File Structure

[Implementation details removed - Opus will design architecture]

#### Configuration Examples

**PrayerConfig.json** - Prayer timing and display rules:
- Calculation method defaults by region
- Prayer duration defaults (Fajr: 15min, Dhuhr: 20min, etc.)
- Buffer times (before: 5min, after: 5min)
- Prayer colors and styling per theme
- Jummah adaptation rules
- Ramadan special timings

**NawafilConfig.json** - Comprehensive voluntary prayer rules:
- Each nawafil type with:
  - Arabic/English names
  - Default rakaat count
  - User-configurable range
  - Suggested times
  - Auto-attachment rules (for rawatib)
- Qiyam al-Layl: Time block specification (not rakaat-based)

**ThemeConfig.json** - Complete theme specifications:
- Color palettes (hex codes)
- Font families and sizes
- Shadow definitions
- Animation timing per theme
- Special theme activation rules (e.g., Ramadan auto-activate)

**AnimationConfig.json** - All animation timing:
- Spring stiffness/damping values
- Easing curves (bezier points)
- Duration multipliers per animation type
- Haptic intensity mappings
- Performance mode toggles (reduce motion support)

#### Benefits of Configuration Approach
1. **Rapid Iteration**: Change timings without recompiling
2. **A/B Testing**: Easy to test different values
3. **Localization**: Separate content from code
4. **Future-Proof**: Add new features without code changes
5. **Personalization**: Users could eventually upload custom configs (Pro feature, v3.0)

---

## Technical Architecture

### Technology Stack

[Implementation details removed - Opus will design architecture]

### Project Structure
[Implementation details removed - Opus will design architecture]

### SwiftData Schema
[Implementation details removed - Opus will design architecture]

### Performance Requirements

#### App Launch Performance
- **Cold Launch Target**: Under 2.0 seconds from tap to usable interface
- **Warm Launch Target**: Under 1.0 seconds when app is in background
- **Measurement**: Time from app icon tap to first interactive frame

#### Memory Usage
- **Baseline Usage**: < 50MB with minimal tasks
- **Peak Usage**: < 150MB with full day schedule + themes
- **Memory Warnings**: Graceful degradation when system memory is low

#### Battery Impact
- **Background Location**: < 2% battery per day (prayer time updates only)
- **Notifications**: < 1% battery per day (standard iOS scheduling)
- **Timeline Rendering**: < 5% battery per hour of active use

#### Animation Performance
- **Frame Rate**: Consistent 60 FPS for all animations
- **Drop Threshold**: < 2 frames dropped per animation sequence
- **Complex Animations**: Must maintain 45 FPS minimum

#### Data Loading
- **Prayer Times**: < 500ms to load cached data
- **Timeline Load**: < 300ms to render full day view
- **Task Creation**: < 100ms from tap to save confirmation

#### Network Performance
- **API Timeout**: 10 seconds for prayer times request
- **Retry Logic**: Exponential backoff with 3 attempts
- **Offline Fallback**: Instant display of cached data

#### Performance Monitoring
- **Metrics Collection**: Firebase Performance Monitoring (opt-in)
- **Crash Reporting**: Crashlytics with symbolication
- **Analytics**: Custom events for performance bottlenecks

---

## API Integration

### Prayer Times API (Aladhan)

#### Endpoint Structure
[Implementation details removed - Opus will design architecture]

#### Service Implementation
[Implementation details removed - Opus will design architecture]

### DeepSeek API (Future - v2.0 Smart Rescheduling)

[Implementation details removed - Opus will design architecture]

### Prayer Calculation Methods

#### Supported Methods (All 8 Available from MVP)

1. **Muslim World League**
   - **Region**: Most of the world except Americas
   - **Fajr Angle**: 18 degrees
   - **Isha Angle**: 17 degrees
   - **Default For**: Europe, Africa, Middle East (except GCC)

2. **Umm al-Qura (Makkah)**
   - **Region**: Saudi Arabia
   - **Source**: Official Saudi authorities
   - **Special**: Uses Umm al-Qura calendar for Hijri dates
   - **Default For**: Saudi Arabia, Kuwait, Bahrain

3. **Egyptian General Authority**
   - **Region**: Egypt, Sudan, Libya
   - **Fajr Angle**: 19.5 degrees
   - **Isha Angle**: 17.5 degrees
   - **Default For**: Egypt, Sudan, Libya, Yemen

4. **University of Islamic Sciences, Karachi**
   - **Region**: Pakistan, Bangladesh, India
   - **Fajr Angle**: 18 degrees
   - **Isha Angle**: 18 degrees
   - **Default For**: Pakistan, Bangladesh, India

5. **Islamic Society of North America (ISNA)**
   - **Region**: USA, Canada
   - **Fajr Angle**: 15 degrees
   - **Isha Angle**: 15 degrees
   - **Default For**: USA, Canada

6. **Dubai (UAE)**
   - **Region**: UAE
   - **Source**: Dubai municipality
   - **Special**: Slightly later Isha calculation
   - **Default For**: UAE

7. **Majlis Ugama Islam Singapura**
   - **Region**: Singapore, Malaysia
   - **Fajr Angle**: 20 degrees
   - **Isha Angle**: 18 degrees
   - **Default For**: Singapore, Malaysia

8. **Diyanet (Turkey)**
   - **Region**: Turkey
   - **Source**: Turkish Religious Affairs
   - **Special**: Custom calculation for Turkish latitudes
   - **Default For**: Turkey

#### High-Latitude Location Handling

**User Choice Approach**:
- When latitude > 48° (northern) or < -48° (southern)
- Show alert: "Extreme latitude detected. Prayer times may be unusual"
- Offer three options:
  1. **Nearest Latitude**: Use times from 48° latitude
  2. **Middle of Night**: Fixed times for Fajr/Isha
  3. **Nearest Day**: Use times from nearest day with normal prayer schedule

**Configuration**:
```json
{
  "highLatitudeMethods": {
    "nearestLatitude": {
      "enabled": true,
      "threshold": 48
    },
    "middleOfNight": {
      "enabled": true,
      "fajrOffset": "01:30",
      "ishaOffset": "01:30"
    },
    "nearestDay": {
      "enabled": true,
      "searchWindow": 7
    }
  }
}
```

#### Method Selection UI

**Settings Flow**:
1. Auto-detect based on location
2. Show "Change method" option
3. Display method name + region it's designed for
4. Show sample times for today
5. Apply immediately with confirmation

**User Education**:
- Brief explanation of each method
- Link to "Learn more" web page
- Recommendation based on user's location

### Error Handling Specifications

#### Network Error Handling

**Prayer API Failures**:
1. **Timeout (> 10 seconds)**
   - Show cached times with warning banner
   - Message: "Last updated: X hours ago"
   - Retry button with exponential backoff

2. **No Internet Connection**
   - Display "Offline Mode" indicator
   - Show cached prayer times (up to 30 days)
   - All other features work normally

3. **API Rate Limiting**
   - Implement request queuing
   - Use cached data until limit resets
   - User notification only if cache > 24 hours

**Cache Strategy**:
```json
{
  "prayerCache": {
    "maxDays": 30,
    "refreshInterval": "24h",
    "fallbackThreshold": "48h",
    "warningThreshold": "24h"
  }
}
```

#### Location Service Errors

**Location Denied**:
- Show manual location selection
- List major cities by country
- Remember user's manual choice

**Location Unavailable**:
- Use last known location
- Show "Using last location" banner
- Offer manual selection

**Poor GPS Accuracy**:
- Use cell tower location
- Increase search radius for prayer times
- Allow manual override

#### Data Corruption Handling

**SwiftData Corruption**:
- Automatic backup creation every 24 hours
- Restore from most recent backup
- User notification: "Data restored from backup"

**Migration Failures**:
- Preserve old data version
- Attempt migration in background
- Fallback to read-only mode

#### Notification Failures

**Permission Denied**:
- Show educational screen about benefits
- Clear instructions to enable in Settings
- Deep link to Settings app

**System Notification Limits**:
- Batch notifications when possible
- Prioritize prayer notifications over tasks
- Use in-app notifications for less critical alerts

#### Error Recovery Strategies

**Graceful Degradation**:
1. **Critical Features**: Timeline, tasks, cached prayers always work
2. **Important Features**: Notifications work with limitations
3. **Nice-to-Have**: Live updates, sync disabled

**User Communication**:
- Clear, non-technical error messages
- Actionable next steps
- Never blame the user
- Offer alternative solutions

**Error Analytics**:
- Track error types and frequency
- Monitor recovery success rates
- Identify common failure patterns
- Optimize based on real-world usage

---

## Business Model & Pricing

### Pricing Tiers

#### Free Version
**Price:** $0  
**Target:** 80-90% of users  
**Goal:** Maximize adoption, reduce barrier to entry

**Features Included:**
- ✅ Unlimited tasks
- ✅ Daily timeline planning
- ✅ Automatic prayer times
- ✅ Basic notifications (at task start, at prayer time)
- ✅ 3 task categories (Work, Personal, Study)
- ✅ Dark mode
- ✅ Drag & drop scheduling
- ✅ Inbox system
- ✅ Manual rescheduling

**Limitations:**
- ❌ No calendar sync
- ❌ No recurring tasks
- ❌ No custom notifications (before/after task)
- ❌ No widgets
- ❌ No Apple Watch app
- ❌ No week view
- ❌ No nawafil prayers
- ❌ No multiple adhan options (default only)
- ❌ No custom prayer durations

#### Mizan Pro
**Price:** 
- **Monthly:** 15 SAR / $4.99
- **Annual:** 100 SAR / $29.99 (save 44%)
- **Lifetime:** 250 SAR / $69.99 (one-time)

**Target:** 5-10% conversion rate  
**Goal:** Sustainable revenue for development

**Additional Features:**
- ✅ Calendar sync (Google, iCloud, Outlook)
- ✅ Unlimited recurring tasks
- ✅ Advanced notifications (before task, after task)
- ✅ Custom notification timing
- ✅ Home screen widgets (3 sizes)
- ✅ Apple Watch app (v1.5+)
- ✅ Week view planning
- ✅ **Nawafil prayer tracking** (Tahajjud, Duha, Witr, Rawatib)
- ✅ Multiple adhan audio options (5+ muezzins)
- ✅ Custom prayer durations & buffer times
- ✅ Smart AI rescheduling (v2.0+)
- ✅ Cloud backup & sync (v2.0+)
- ✅ Priority support
- ✅ Export data (CSV, JSON)

### Regional Pricing Strategy
[Implementation details removed - Opus will design architecture]

### Revenue Projections

#### Year 1 (Conservative)
[Implementation details removed - Opus will design architecture]

#### Year 1 (Realistic)
[Implementation details removed - Opus will design architecture]

#### Year 1 (Optimistic)
[Implementation details removed - Opus will design architecture]

### Paywall Strategy

#### When to Show Paywall
[Implementation details removed - Opus will design architecture]

#### Paywall UI
[Implementation details removed - Opus will design architecture]

### Pro Upgrade Flow

#### Upgrade Triggers
- **Feature Access**: When user taps Pro-locked feature
- **Settings Prompt**: "Upgrade to Pro" button in settings
- **Natural Breaks**: After completing first week of usage
- **Limited Offers**: Special promotions during Ramadan/Eid

#### Feature Carousel Onboarding

**Carousel Structure** (5 screens):
1. **Welcome to Pro**
   - Animated headline: "Unlock Your Full Potential"
   - 3 key benefits highlighted with icons
   - Swipe hint animation

2. **Nawafil Prayers**
   - Visual demonstration of nawafil on timeline
   - Animation showing auto-scheduling
   - "Never miss voluntary prayers" message

3. **Advanced Scheduling**
   - Side-by-side comparison: Basic vs Pro notifications
   - Calendar sync animation
   - Week view preview

4. **Beautiful Themes**
   - Auto-cycling through 5 Pro themes
   - Smooth transitions between themes
   - "Personalize your experience" message

5. **Get Started**
   - Pricing options (Monthly/Annual/Lifetime)
   - Regional pricing display
   - "Start Free Trial" CTA

#### Interactive Elements
- **Quick Animations**: Each screen has a subtle looping animation
- **Tap to Explore**: Users can tap elements to see more detail
- **Live Preview**: Theme changes apply immediately when selected
- **Progress Indicator**: Dots showing carousel position

#### Migration Process
1. **Data Preservation**: All existing tasks and settings remain
2. **Feature Activation**: Pro features unlock instantly after payment
3. **Seamless Transition**: User returns to exact screen they came from
4. **Confirmation**: Success animation with "Welcome to Pro" message

#### Trial Experience
- **Duration**: 7 days full access
- **No Card Required**: Apple handles trial automatically
- **Reminder Notifications**: 24 hours before trial ends
- **Grace Period**: 24 hours after trial to retain data

---

## Development Roadmap

### Phase 1: MVP (Months 1-3)

#### Month 1: Foundation
**Week 1-2:**
- ✅ Project setup (Xcode, Git, SwiftData)
- ✅ Core data models (Task, PrayerTime, UserSettings)
- ✅ Prayer API integration
- ✅ Location services setup

**Week 3-4:**
- ✅ Basic timeline UI (no drag-and-drop yet)
- ✅ Prayer times display
- ✅ Simple task list

#### Month 2: Core Features
**Week 1-2:**
- ✅ Drag & drop implementation
- ✅ Collision detection (prayer conflicts)
- ✅ Task management (add, edit, delete)
- ✅ Inbox system

**Week 3-4:**
- ✅ Notification system (prayers + tasks)
- ✅ Settings screen
- ✅ Basic onboarding

#### Month 3: Polish & Launch
**Week 1:**
- ✅ UI polish, animations
- ✅ Dark mode
- ✅ Error handling, loading states
- ✅ Offline mode

**Week 2:**
- ✅ Testing (unit, UI, beta)
- ✅ Bug fixes
- ✅ Performance optimization

**Week 3:**
- ✅ App Store assets (screenshots, video, description)
- ✅ Press kit
- ✅ Landing page (mizanapp.com)

**Week 4:**
- ✅ App Store submission
- ✅ Launch marketing campaign
- ✅ Monitor initial feedback

### Phase 2: Post-Launch (Months 4-6)

#### Month 4: Quick Wins
- ✅ Home screen widgets (3 sizes)
- ✅ Week view
- ✅ Bug fixes from user feedback
- ✅ Performance improvements

#### Month 5-6: Pro Features
- ✅ Calendar sync (Google, iCloud, Outlook)
- ✅ Advanced notifications
- ✅ Recurring tasks improvements
- ✅ Nawafil prayers system
- ✅ Custom adhan options

### Phase 3: Growth (Months 7-12)

#### Month 7-9: Platform Expansion
- ✅ iPad optimization
- ✅ Apple Watch app
- ✅ Backend + cloud sync
- ✅ Export/import data

#### Month 10-12: AI Features
- ✅ DeepSeek API integration
- ✅ Smart rescheduling algorithm
- ✅ Task duration predictions
- ✅ Intelligent suggestions

### Phase 4: Year 2
- ✅ Android version
- ✅ Web app
- ✅ Ramadan mode
- ✅ Travel mode
- ✅ Team/family features
- ✅ API for third-party integration

---

## User Experience

### Onboarding Flow Details

#### Quick Setup Wizard (4 Steps)

**Step 1: Welcome & Value Proposition**
- Beautiful splash with Mizan logo and tagline
- Key benefit: "Plan your day around prayer, not around meetings"
- Animation showing timeline with prayer anchors
- "Get Started" button

**Step 2: Location Permission**
- Clear explanation: "We need your location for accurate prayer times"
- Visual map showing user's approximate location
- Privacy reassurance: "Your location stays on your device"
- "Allow Location" button with iOS permission dialog

**Step 3: Calculation Method Selection**
- Auto-select based on detected location
- Show method name with country flag
- "Change Method" option for advanced users
- Brief explanation of why this matters

**Step 4: Notification Permissions**
- Explain benefits: "Reminders for prayers and tasks"
- Show sample notification card
- "Enable Notifications" button with iOS permission dialog
- Optional: "Skip for now" (can enable later)

#### Timeline Tutorial (Interactive)

**First Launch Experience**:
1. **Empty Timeline** with prayer blocks visible
2. **Floating Tooltip**: "This is your day. Prayer times are already here"
3. **Task Creation**: Animated prompt to create first task
4. **Drag & Drop**: Guided interaction to schedule task
5. **Success**: Celebration animation with "You're all set!"

#### Progressive Feature Introduction

**Day 1**: Basic timeline and task creation
**Day 3**: Introduce task categories
**Day 7**: Suggest recurring tasks (Pro feature)
**Day 14**: Showcase theme options (Pro feature)

#### Skip Options

- **Quick Start**: Skip all tutorials, go straight to app
- **Later**: Remind in 24 hours
- **Never**: Don't show again (in settings)

### Competitive Differentiation

#### Superior Execution Strategy

**1. Best-in-Class Animations**
- 60 FPS guarantee across all interactions
- Spring physics that feel natural, not jarring
- Micro-interactions that delight users
- Haptic feedback synchronized with visual cues
- Benchmark: Faster and smoother than Structured

**2. Most Accurate Prayer Times**
- All 8 calculation methods from day one
- High-latitude handling with user choice
- Mosque time adjustment feature
- Real-time updates when traveling
- Benchmark: More accurate than Muslim Pro

**3. Exceptional User Experience**
- Arabic-first design from ground up
- RTL layout perfection
- Contextual help throughout app
- No guilt approach to prayer tracking
- Benchmark: More intuitive than any competitor

**4. Performance Excellence**
- < 2 second launch time guarantee
- Offline-first architecture
- Efficient memory usage
- Minimal battery impact
- Benchmark: Lighter and faster than all competitors

**5. Customer Support**
- 24-hour response time for Pro users
- Comprehensive in-app help
- Video tutorials for complex features
- Community forum for user tips
- Benchmark: Better support than paid competitors

#### Moat Building

**Technical Moat**:
- Proprietary collision detection algorithm
- Unique prayer-as-infrastructure approach
- Advanced caching for offline use
- Configuration-driven architecture for rapid iteration

**Design Moat**:
- Distinctive visual identity
- Signature animations
- Theme system that competitors can't easily replicate
- Attention to detail in every interaction

**Community Moat**:
- Early user feedback integration
- Transparent development roadmap
- User-driven feature prioritization
- Educational content about prayer and productivity

---

## Testing Strategy

### Unit Tests
[Implementation details removed - Opus will design architecture]

### UI Tests
[Implementation details removed - Opus will design architecture]

### Beta Testing
- **TestFlight**: 100-500 users
- **Duration**: 2-4 weeks
- **Feedback**: In-app form + email
- **Incentive**: Lifetime Pro for top 50 testers

---

## Launch Checklist

### Pre-Launch (Week before)
- [ ] Final QA pass (no critical bugs)
- [ ] App Store assets uploaded
- [ ] Landing page live
- [ ] Press kit ready
- [ ] Social media accounts set up
- [ ] Analytics configured (App Store Connect, Firebase)
- [ ] Email list ready (from waitlist)
- [ ] Product Hunt submission prepared

### Launch Day
- [ ] App Store release (9 AM PST)
- [ ] Product Hunt launch
- [ ] Twitter announcement thread
- [ ] Instagram/TikTok posts
- [ ] Email to waitlist
- [ ] Reddit posts (r/productivity, r/islam)
- [ ] Hacker News post
- [ ] Muslim tech blogs outreach

### Post-Launch (First Week)
- [ ] Monitor crash reports
- [ ] Respond to reviews
- [ ] Track analytics daily
- [ ] Iterate on onboarding based on feedback
- [ ] Plan first update (v1.1)

---

## Success Metrics

### Acquisition
- **Downloads**: 10K (Month 1), 50K (Year 1)
- **App Store ranking**: Top 100 in Productivity (Saudi Arabia)
- **Organic vs Paid**: 80% organic

### Engagement
- **DAU/MAU ratio**: > 30%
- **Session length**: > 5 minutes
- **Tasks created per user**: > 10/week
- **Retention D1**: > 40%, D7: > 25%, D30: > 15%

### Revenue
- **Free → Pro conversion**: 5-10%
- **MRR (Monthly Recurring Revenue)**: $5K (Month 3), $40K (Year 1)
- **LTV**: > $40
- **CAC**: < $2

### Quality
- **App Store rating**: > 4.5 stars
- **Crash rate**: < 1%
- **Support tickets**: < 5% of users

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Low adoption | Medium | High | Strong marketing, generous free tier, referral program |
| Prayer API downtime | Low | High | 30-day cache, local fallback calculations |
| Apple rejection | Low | High | Follow guidelines, no controversial content |
| Revenue below target | Medium | Medium | Adjust pricing, add features, optimize conversion |
| Competitors copy | High | Medium | Move fast, build community moat, patent UI |
| Technical debt | Medium | Medium | Weekly refactoring, code reviews |

---

## Conclusion

Mizan solves a real problem for millions of Muslims who struggle to integrate prayer into their productive lives. By treating prayer as scheduling infrastructure rather than an interruption, we create a fundamentally better planning experience.

### Next Steps
1. **Approve this PRD** (adjustments?)
2. **Set up development environment** (Xcode project)
3. **Design mockups** (Figma or direct coding?)
4. **Begin coding MVP** (start with prayer API integration)

**Estimated MVP Time**: 3 months (with Claude Code assistance)  
**Target Launch**: Q2 2026  
**Go/No-Go Decision**: After 100 beta testers give feedback

---

*"Indeed, prayer has been decreed upon the believers a decree of specified times."* (Quran 4:103)

Let's build something that makes this easier. 🤲

---

## Appendix A: Code Snippets Repository

Ready-to-use code for vibe coding sessions:

### A1: SwiftData Setup
[Implementation details removed - Opus will design architecture]

### A2: Notification Handling in AppDelegate
[Implementation details removed - Opus will design architecture]

### A3: Color Extensions
[Implementation details removed - Opus will design architecture]

---

**END OF PRD**

Ready to build? 🚀


---

## Additional Features & Considerations

### Features Not Explicitly Mentioned (But Likely Needed)

#### 1. **Prayer Time Adjustments**
- Manual prayer time offset (±5 minutes per prayer)
- Useful for users who follow mosque timings that differ from calculation
- Example: User's mosque does Isha 10 minutes later than calculated time

#### 2. **Travel Mode**
- Detect when user travels to different city/country
- Automatically update prayer times
- Option to combine prayers (Dhuhr+Asr, Maghrib+Isha) when traveling
- Notification: "Prayer times updated for your new location"

#### 3. **Qasr (Shortened Prayers) for Travelers**
- Toggle in settings: "I am traveling"
- Affects 4-rakaat prayers (Dhuhr, Asr, Isha) → shortened to 2 rakaat
- Visual indicator on timeline: "✈️" badge
- Automatic detection based on distance from home (Pro feature)

#### 4. **Prayer at Mosque vs Home**
- Toggle per prayer: "I pray [prayer name] at mosque"
- Adds travel time buffer before prayer
- Different duration estimate (mosque prayer usually longer)
- Location-based auto-toggle (if near mosque at prayer time)

#### 5. **Adhan Customization**
- Volume control per prayer
- Different muezzins per prayer (advanced users)
- Silent mode for work hours (Dhuhr/Asr only)
- Option to use device ringtone instead of adhan

#### 6. **Qibla Direction** (Minimal Integration)
- NOT a full Qibla compass app
- Simple arrow on prayer reminder notification
- Shows direction based on current location
- Link to full Qibla app if user needs more

#### 7. **Hijri Calendar Display**
- Toggle to show Hijri date alongside Gregorian
- Important for tracking Ramadan, Dhul Hijjah, etc.
- Prayer times API already provides Hijri date
- Display in header: "13 Rajab 1448" 

#### 8. **Fasting Days Integration** (Pro)
- Mark Mondays & Thursdays (Sunnah fasting)
- Ayyam al-Bid (13-15 of each lunar month)
- Day of Arafah, Ashura, etc.
- Suhoor reminder on fasting days
- Gentle all-day reminder: "You are fasting today 🌙"

#### 9. **Siri Shortcuts Support**
- "Hey Siri, show me today's prayers"
- "Hey Siri, add task to Mizan"
- "Hey Siri, how long until next prayer?"
- Available in iOS 18+ (v1.5 feature)

#### 10. **Today Widget (iOS 18)**
- Lock screen widget showing next prayer countdown
- Compact home screen widget showing day overview
- Can glance at prayer times without opening app

#### 11. **Apple Watch Complications**
- Next prayer time
- Prayer countdown
- Today's remaining prayers
- Quick "Mark prayer complete" (Nawafil)

#### 12. **Data Privacy & Security**
- All data stored locally (SwiftData)
- No account required for free features
- Pro subscription via Apple (no email needed)
- Option to export data (CSV/JSON)
- Option to delete all data
- Clear privacy policy: "We never see your prayer history"

#### 13. **Accessibility Features**
- VoiceOver support (critical for blind users)
- Dynamic Type (font size scaling)
- Reduce Motion mode (disable animations for sensitive users)
- High contrast themes
- RTL layout perfection (for Arabic)

#### 14. **Onboarding Experience**
- Welcome screen with app value proposition
- Location permission explanation
- Notification permission explanation
- Prayer calculation method selection
- Optional: Import tasks from Reminders app

#### 15. **Empty States & Error Handling**
- No internet: "Showing cached prayer times"
- Location disabled: "Enable location for accurate prayer times"
- No tasks scheduled: Beautiful illustration + CTA
- Permission denied: Helpful instructions

#### 16. **Performance Optimizations**
- Lazy loading of timeline (only visible hours)
- Image caching (for theme assets)
- Debounced search in task inbox
- Efficient SwiftData queries with indexes

#### 17. **Offline Mode Resilience**
- Full functionality without internet
- 30-day prayer time cache
- Task management works offline
- Sync when internet returns (v2.0 cloud sync)

---

## App Store Metadata

### App Name Options
- **Primary**: Mizan - Prayer & Planner
- **Alt 1**: Mizan: Islamic Daily Planner
- **Alt 2**: Mizan - Plan Around Prayer

### Keywords (ASO)
Arabic: صلاة، منظم، مهام، يومي، إسلامي، نافلة، رمضان، إنتاجية
English: prayer, planner, tasks, Islamic, productivity, salah, Ramadan, schedule

### App Description (Arabic - 4000 characters max)
Focus on:
- Prayer-first planning (unique selling point)
- Beautiful design
- No tracking/guilt
- Free vs Pro features
- Social proof (ratings, downloads)

### Screenshots Strategy (10 images)
1. Timeline view with prayers + tasks (hero shot)
2. Drag & drop in action
3. Prayer notification
4. Theme showcase (cycle through 5 themes)
5. Nawafil settings (Pro feature teaser)
6. Week view (Pro feature teaser)
7. Ramadan mode special UI
8. Widgets on home screen
9. Apple Watch app
10. Testimonial screenshot (5-star reviews)

### Preview Video (30 seconds)
- 0-5s: Problem (other apps ignore prayer)
- 5-15s: Solution (Mizan timeline with prayer anchors)
- 15-25s: Key features (drag-drop, notifications, themes)
- 25-30s: CTA (Download now)

---

## Support & Feedback

### In-App Feedback
- Shake device → Feedback form
- Settings → "Send Feedback"
- Attach screenshot + device info automatically

### Support Channels
- Email: support@mizanapp.com
- Twitter: @MizanApp
- Website: https://mizanapp.com/support

### FAQ Page
- How do I change prayer calculation method?
- Why don't my tasks sync across devices? (v2.0 feature)
- How do I get refund for Pro?
- Can I use Mizan offline?
- How accurate are prayer times?

---

## Localization Expansion (Post-MVP)

### Phase 1 Languages (v1.1)
- Arabic (complete)
- English (complete)

### Phase 2 Languages (v2.0)
- Urdu (Pakistan, India)
- Indonesian (Indonesia, Malaysia)
- Turkish (Turkey)
- French (North Africa, France)

### Phase 3 Languages (v3.0)
- Bengali (Bangladesh)
- Persian (Iran)
- Malay (Malaysia, Singapore)
- German, Spanish, etc.

---

## Legal & Compliance

### Required Documents
- Privacy Policy (GDPR, CCPA compliant)
- Terms of Service
- End User License Agreement (EULA)
- Refund Policy (standard Apple terms)

### App Store Guidelines Compliance
- No third-party ads (violates religious app guidelines)
- Clear Pro subscription terms
- Accurate prayer times (cite Aladhan API)
- Accessible to users with disabilities
- No misleading claims about prayer tracking

### Data Collection Transparency
- Location: Only for prayer times (not tracked)
- Notifications: Only for prayers/tasks (not marketing)
- Analytics: Minimal, anonymized (Firebase optional)
- No selling user data (clearly stated)

---

## END OF PRD

This document is comprehensive but not exhaustive. Additional edge cases and features may emerge during development. Use your best judgment and Islamic knowledge to fill gaps responsibly.

**May Allah accept this work and make it beneficial. آمين**