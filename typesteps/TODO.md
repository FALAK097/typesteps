# Product Requirements Document (PRD)

## App Name: TypeSteps (working title)

---

## 1. Overview

TypeSteps is a macOS application that passively tracks the number of letters a user types each day across the system.  
The app provides daily, weekly, and monthly insights into typing activity, similar to a step counter but for keyboard usage.

The product is privacy-focused: it only counts characters and never records or stores actual typed content.

---

## 2. Goals

- Track total letters typed per day
- Show historical typing data (daily, weekly, monthly)
- Provide simple insights about typing habits
- Be lightweight, unobtrusive, and privacy-first
- Serve as a beginner-friendly Swift + SwiftUI macOS app

---

## 3. Non-Goals

- No keylogging or text storage
- No cloud sync (initial version)
- No productivity scoring or gamification (v1)
- No per-app breakdown (v1)

---

## 4. Target Platform

- macOS 13+
- Apple Silicon & Intel Macs
- Menu bar app with optional main window

---

## 5. Core Features

### 5.1 Keystroke Counting

- Count letters typed system-wide
- Supported characters:
  - A–Z, a–z
  - Numbers (0–9)
  - Optional: punctuation (future toggle)
- Ignore:
  - Modifier keys (Shift, Cmd, Option, Control)
  - Arrow keys and function keys

---

### 5.2 Daily Tracking

- Automatically reset counter at midnight (local time)
- Store:
  - Date
  - Total letters typed

---

### 5.3 Weekly & Monthly Aggregation

- Weekly view:
  - Total letters typed this week
  - Daily breakdown
- Monthly view:
  - Total letters typed this month
  - Average per day

---

### 5.4 Insights

- Most active day
- Average letters per day
- Best week (highest total)

---

### 5.5 Menu Bar UI

- Menu bar icon showing:
  - Today’s letter count
- Dropdown:
  - Today
  - This Week
  - This Month
  - Open Dashboard
  - Settings

---

### 5.6 Dashboard Window

- Simple SwiftUI views
- Charts:
  - Daily bar chart
  - Weekly summary
- Clean, Apple-like design

---

### 5.7 Privacy & Permissions

- Uses macOS Accessibility APIs
- Displays a clear explanation before requesting permission
- No text, words, or keystrokes are stored
- Only numeric counts are saved

---

## 6. Data Storage

### Initial Version

- UserDefaults
- Structure:

  ```json
  {
    "2026-01-01": 5423,
    "2026-01-02": 6101
  }

Future Upgrade

CoreData for scalability

1. Technical Architecture
Key Modules
KeystrokeListener

Listens to global key events

Filters valid characters

Emits increment events

StatsManager

Aggregates daily, weekly, monthly data

Handles date boundaries

StorageManager

Saves and retrieves counts

UI Layer

SwiftUI views

MenuBarExtra

Charts

1. Edge Cases

App not running → no counting

Permission revoked → show warning

System sleep / wake handling

Timezone change handling

1. Success Metrics

App runs with <1% CPU usage

No crashes during long sessions

Accurate daily resets

Clear user trust around privacy

1. Future Enhancements

Per-app typing stats

Export data (CSV)

iCloud sync

Typing streaks

Heatmap calendar view

1. Risks

Accessibility permission friction

macOS security changes

User trust concerns around keystroke tracking

1. Open Questions

Should punctuation count by default?

Should there be a pause/disable mode?

Should stats reset be customizable?

---

## 6. Suggested learning + build order (very important)

Since you’re new to Swift, **do NOT start with keystrokes**.

### Phase 1 – Swift & SwiftUI basics (2–3 days)

- Swift variables, structs, enums
- SwiftUI views, `@State`, `@AppStorage`
- Menu bar app basics

### Phase 2 – Fake data dashboard (2 days)

- Hardcode daily numbers
- Build charts and UI
- Get confident with SwiftUI

### Phase 3 – Persistence (1 day)

- Save daily counts
- Date handling

### Phase 4 – Keystroke tracking (advanced)

- Accessibility permission
- Event tap
- Character filtering
