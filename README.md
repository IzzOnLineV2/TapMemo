# TapMemo

**Speak it, and it's on your calendar.** TapMemo is an iOS app that turns a spoken phrase into a
memo — and, when your words contain a date or time, automatically creates the matching **Calendar
event** or **Reminder**. No typing, no menus: tap the mic, say *"ricordami la spesa domani alle 3"*,
and it's done.

TapMemo is **Italian-first**: both the speech recognition and the natural-language date parser are
tuned for Italian (`it-IT`). The interface is localized in **Italian (source) and English**.

There's **no account, no backend, no tracking, no third-party SDKs** — everything runs on device and
writes only to *your own* calendar and reminders. The app ships on the App Store; the source is
released under the [MIT license](LICENSE).

## What it does

- 🎤 **Tap to record** — Apple's Speech framework transcribes what you say.
- 🧠 **Understands Italian dates** — `MemoParser` pulls a clean title and a due date/time out of
  natural phrases: *domani, dopodomani, sabato 25, alle 3, ore 9:15, stasera, a mezzogiorno*… with
  sensible Italian defaults (e.g. *"alle 3"* is read as 15:00, day-only memos default to 09:00).
- 📅 **Auto-creates events** — if a date is detected, the memo becomes a Calendar event automatically.
- ✅ **One-swipe actions** — add to Reminders, add to Calendar, share, or delete a memo.
- 🔁 **Stays in sync** — if you delete the underlying event/reminder in Apple's apps, TapMemo notices
  on next launch and updates the memo's status.
- 🧩 **Home-screen widget** — small / medium / large widgets show your recent memos and a one-tap
  record button (via the `tapmemo://record` deep link).

## How it works

The app is a small, dependency-free SwiftUI + SwiftData project.

| File | Role |
|---|---|
| `TapMemo/TapMemoApp.swift` | `@main`; builds the SwiftData `ModelContainer` on a **shared App Group** store so the widget can read the same data |
| `TapMemo/ContentView.swift` | Record button, memo list, swipe actions, success banner, EventKit re-sync on foreground |
| `TapMemo/Item.swift` | `MemoItem` — the `@Model` that is persisted (title, original transcript, due date, calendar/reminder ids) |
| `TapMemo/VoiceManager.swift` | Records audio and runs Apple speech recognition (`it-IT`) |
| `TapMemo/MemoParser.swift` | Italian natural-language → `(title, dueAt)`; the app's core heuristic |
| `TapMemo/MemoCreationService.swift` | Orchestrates parse → save → EventKit → widget reload |
| `TapMemo/EventKitService.swift` | `actor` wrapping Calendar & Reminders create/delete/exists |
| `TapMemo/Haptics.swift` | Haptic feedback helpers |
| `TapMemo/TapMemoWidget.swift` | Widget timeline provider + S/M/L views (reads the shared store **read-only**) |
| `TapMemoWidget/TapMemoWidgetBundle.swift` | `@main` widget bundle |
| `TapMemo/*.xcstrings` | Localized UI strings (`it` source, `en`) and permission prompts |
| `SCHEMA_VERSIONING.md` | How to migrate the SwiftData schema across app versions without losing user data |

## Data & privacy

- **Memos** are stored **on device** in a SwiftData/SQLite database inside a shared App Group
  (`group.com.smartapibox.tapmemo` → `TapMemo.sqlite`), which is what lets the widget display them.
- **Calendar events and reminders** are written to *your own* calendars through EventKit.
- **Speech** is transcribed via Apple's Speech framework. There is no custom server, no analytics,
  and no third-party code.
- Permissions requested: **microphone**, **speech recognition**, **calendar** (full access) and
  **reminders** (full access).

## Requirements & build

- Xcode 26+, Swift 5, **iOS 26.2+**.
- Open `TapMemo.xcodeproj`.
- On the **TapMemo** and **TapMemoWidgetExtension** targets → *Signing & Capabilities* → set your
  **Team**. Both already declare the App Group `group.com.smartapibox.tapmemo`.
- Run on a **real device** — the microphone and speech recognition don't work in the Simulator.

## Project layout

```
TapMemo/                 Main app (SwiftUI + SwiftData) — app, parsing, EventKit, voice, widget views
TapMemoWidget/           Widget extension bundle, assets, Info.plist, entitlements
TapMemoTests/            Unit tests
TapMemoUITests/          UI tests
SCHEMA_VERSIONING.md     SwiftData schema-migration guide
TapMemo.xcodeproj        Xcode project
```

## Schema versioning

When you change the `MemoItem` `@Model`, the on-device database must be migrated so existing users
don't lose data (or crash). See [`SCHEMA_VERSIONING.md`](SCHEMA_VERSIONING.md) for the
`VersionedSchema` / `SchemaMigrationPlan` approach and a step-by-step checklist.

## License

TapMemo is released under the [MIT License](LICENSE) — you're free to use, modify, and distribute
the code. The **"TapMemo" name, icon, and branding are not covered by the license** and remain the
property of IzzOnLine di Stefania Izzo; please don't publish a copy under the same identity.
