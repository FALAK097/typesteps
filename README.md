# TypeSteps

![Homebrew Downloads](https://img.shields.io/homebrew/cask-downloads/typesteps)

TypeSteps is a privacy-focused macOS application that passively tracks the number of characters you type each day system-wide. Think of it as a step counter—but for your keyboard!

<img width="1913" height="1314" alt="image" src="https://github.com/user-attachments/assets/acdebf0f-9b74-428c-af20-4582368264a7" />

## Features

- **System-Wide Keystroke Counting:** Runs quietly in the background, counting letters, numbers, punctuation, and whitespace typed across all apps. Does not track modifier keys alone (Shift, Ctrl, Cmd, Option), function keys, or keyboard shortcuts.
- **Privacy First:** Never records or stores actual typed characters. It only increments a numeric counter, which is saved locally on your device.
- **Historical Insights:** View your typing metrics with daily, weekly, and monthly stats.
- **Menu Bar Integration:** A lightweight presence in your menu bar.
- **WakaTime Sync (Optional):** Link your WakaTime API key to see more developer metrics.

## Requirements

- macOS 13+
- Apple Silicon or Intel Mac

## Installation

### Option 1: Homebrew (Recommended)

1. Add the custom tap to Homebrew:

   ```bash
   brew tap FALAK097/typesteps
   ```

2. Install the app:

   ```bash
   brew install --cask typesteps
   ```

### Option 2: Build from Source

1. Clone the repository:

   ```bash
   git clone https://github.com/FALAK097/typesteps.git
   ```

2. Open `typesteps.xcodeproj` in Xcode (requires Xcode 16+ or compatible versions).
3. Build and Run.

**Note:** As TypeSteps uses macOS Accessibility APIs to listen to keystrokes on a system level, you must grant Accessibility permissions in **System Settings > Privacy & Security > Accessibility** upon its first launch.

## Data Storage

All data is stored purely locally on your machine using `UserDefaults` and/or CoreData equivalent. Characters are never transmitted over the internet (unless you opt-in to fetch developer stats via the WakaTime API).
