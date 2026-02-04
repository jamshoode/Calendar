# Liquid Glass Calendar - Implementation Plan

## Project Overview
A multiplatform (iOS/macOS) calendar application with Liquid Glass design, featuring calendar view with swipe navigation, timer with presets and pomodoro mode, alarm clock, and iOS WidgetKit widget support.

---

## Architecture & Patterns

### MVVM Architecture
- **Models**: SwiftData entities (Event, TimerSession, Alarm, TimerPreset)
- **ViewModels**: Business logic and state management
  - CalendarViewModel: Month navigation, date selection, events
  - TimerViewModel: Timer logic, presets, pomodoro cycles
  - AlarmViewModel: Alarm time management, toggle state
  - EventViewModel: Event CRUD operations
- **Views**: SwiftUI views observing ViewModels

### State Management
- SwiftUI built-in: `@State`, `@StateObject`, `@ObservedObject`, `@Environment`
- SwiftData: `@Query`, `@Model`, modelContext for persistence
- AppState: Global app state (current tab, theme, etc.)

---

## Project Structure

```
CalendarApp/
├── App/
│   ├── CalendarApp.swift                 # App entry point
│   ├── AppState.swift                    # Global app state
│   └── AppDelegate.swift                 # App lifecycle & notifications
├── Core/
│   ├── Models/
│   │   ├── Event.swift                   # SwiftData model
│   │   ├── TimerSession.swift            # Active timer tracking
│   │   ├── Alarm.swift                   # Alarm configuration
│   │   └── TimerPreset.swift             # Saved timer presets
│   ├── ViewModels/
│   │   ├── CalendarViewModel.swift
│   │   ├── TimerViewModel.swift
│   │   ├── AlarmViewModel.swift
│   │   └── EventViewModel.swift
│   └── Services/
│       ├── NotificationService.swift     # Local notifications
│       └── AudioService.swift            # Alarm/timer sounds
├── Features/
│   ├── Calendar/
│   │   ├── Views/
│   │   │   ├── CalendarView.swift        # Main calendar container
│   │   │   ├── MonthView.swift           # Month grid display
│   │   │   ├── DayCell.swift             # Individual day cell
│   │   │   ├── EventListView.swift       # Events for selected date
│   │   │   └── AddEventView.swift        # Add/edit event sheet
│   │   └── Components/
│   │       ├── SwipeGestureModifier.swift # Month navigation
│   │       └── EventIndicator.swift      # Event dots on calendar
│   ├── Timer/
│   │   ├── Views/
│   │   │   ├── TimerView.swift           # Main timer container
│   │   │   ├── CountdownView.swift       # Standard countdown
│   │   │   ├── PomodoroView.swift        # Pomodoro timer UI
│   │   │   └── PresetsGrid.swift         # Preset buttons grid
│   │   └── Components/
│   │       ├── TimerDisplay.swift        # Large time display
│   │       └── TimerControls.swift       # Play/pause/reset
│   └── Alarm/
│       ├── Views/
│       │   ├── AlarmView.swift           # Main alarm view
│       │   └── TimePicker.swift          # Custom time picker
│       └── Components/
│           └── AlarmToggle.swift         # Enable/disable toggle
├── Shared/
│   ├── Components/
│   │   ├── GlassCard.swift               # Reusable glass card
│   │   ├── GlassButton.swift             # Glass-styled button
│   │   ├── GlassBackground.swift         # Glass background modifier
│   │   ├── AdaptiveTabBar.swift          # iOS tab bar
│   │   └── AdaptiveSidebar.swift         # macOS sidebar
│   ├── Extensions/
│   │   ├── Color+Glass.swift             # Glass color utilities
│   │   ├── View+Glass.swift              # View modifiers
│   │   └── Date+Extensions.swift         # Date utilities
│   └── Utilities/
│       ├── Constants.swift               # App constants
│       └── Formatters.swift              # Date/time formatters
└── Widget/
    ├── CalendarWidget.swift              # Widget configuration
    ├── CalendarWidgetView.swift          # Widget UI
    ├── Provider.swift                    # Timeline provider
    ├── CalendarWidgetBundle.swift        # Widget bundle
    └── WeekView.swift                    # Week dates display
```

---

## Data Models (SwiftData)

### Event
```swift
@Model
class Event {
    var id: UUID
    var date: Date
    var title: String
    var notes: String?
    var color: String
    var createdAt: Date
    
    init(date: Date, title: String, notes: String? = nil, color: String = "blue")
}
```

### TimerSession
```swift
@Model
class TimerSession {
    var id: UUID
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var type: TimerType // .countdown, .pomodoroWork, .pomodoroBreak
    var startTime: Date?
    var isActive: Bool
    var isPaused: Bool
    
    init(duration: TimeInterval, type: TimerType)
}
```

### Alarm
```swift
@Model
class Alarm {
    var id: UUID
    var time: Date
    var isEnabled: Bool
    var soundName: String
    var repeatDays: [Int] // 0 = Sunday, 1 = Monday, etc.
    
    init(time: Date, soundName: String = "default")
}
```

### TimerPreset
```swift
@Model
class TimerPreset {
    var id: UUID
    var duration: TimeInterval
    var label: String
    var icon: String
    var order: Int
    
    init(duration: TimeInterval, label: String, icon: String, order: Int)
}
```

---

## Features Breakdown

### 1. Calendar Feature

**Month Grid:**
- 7-column grid (Monday-Sunday)
- Display previous/next month days (grayed out)
- Current day highlight
- Swipe left/right to change months
- Header with month/year and navigation arrows

**Event Indicators:**
- Small colored dots under dates with events
- Max 3 dots per day
- Color-coded by event type/category

**Event List:**
- Appears when date is selected
- Scrollable list of events for that date
- Shows title, time, and color indicator
- Tap to edit, swipe to delete

**Add/Edit Event:**
- Sheet presentation
- Title text field
- Notes text area
- Date picker
- Color picker
- Save/Cancel buttons

### 2. Timer Feature

**Countdown Timer:**
- Large digital display (MM:SS)
- Circular progress indicator
- Play/Pause button
- Reset button
- Background timer support (notifications)

**Timer Presets:**
- Grid of preset buttons: 1min, 5min, 10min, 15min, 20min, 30min, 45min, 60min
- Custom timer input
- Visual feedback on selection

**Pomodoro Timer:**
- 25-minute work sessions
- 5-minute short breaks
- 15-minute long breaks (after 4 work sessions)
- Auto-transition between work/break
- Session counter display
- Manual skip break option

### 3. Alarm Feature

**Time Selection:**
- Wheel-style time picker
- AM/PM toggle
- Quick preset times

**Alarm Management:**
- Single alarm support
- Enable/disable toggle
- Next alarm time display
- Time remaining until alarm

**Notification:**
- Full-screen alarm trigger
- Snooze option (5, 10, 15 minutes)
- Stop alarm button
- Sound playback

### 4. Widget

**Medium Widget:**
- Week view (Mon-Sun) with day numbers
- Current day highlight
- Small timer icon with countdown (if active)
- Small alarm icon if alarm is set

**Large Widget:**
- Expanded week view
- Additional calendar mini-view
- More prominent timer display
- Event count for current day

---

## UI/UX Design

### Liquid Glass Theme
- Use `.glassBackgroundEffect()` modifier
- Materials: `.ultraThinMaterial`, `.thinMaterial`
- Rounded corners (16-24pt)
- Subtle borders (0.5pt, 20% opacity white)
- System adaptive (light/dark mode)

### Color Palette
- Primary: System accent color
- Glass: White/gray with opacity
- Background: System background
- Text: Primary/secondary labels
- Event colors: Blue, Green, Orange, Red, Purple, Pink, Yellow

### Typography
- Large display: System font, bold, 48-64pt (timer)
- Headers: System font, semibold, 20-28pt
- Body: System font, regular, 16-17pt
- Captions: System font, regular, 12-14pt

### Animations
- Month transition: Horizontal slide with opacity
- Timer digits: Subtle scale pulse when running
- Button presses: Scale 0.95 on tap
- Glass shimmer: Optional subtle gradient animation

---

## Platform Adaptation

### iOS
- Bottom tab bar with 3 tabs (Calendar, Timer, Alarm)
- Sheet presentations for add/edit
- Widget support (home screen)
- Portrait and landscape support

### macOS
- Sidebar navigation
- Larger window sizes
- Menu bar integration
- Keyboard shortcuts

### Adaptive Components
- `AdaptiveNavigationView`: Shows tab bar on iOS, sidebar on macOS
- `AdaptiveSheet`: Uses sheet on iOS, popover on macOS
- Platform-specific layout adjustments

---

## Services

### NotificationService
```swift
class NotificationService {
    func requestAuthorization()
    func scheduleTimerNotification(duration: TimeInterval)
    func scheduleAlarmNotification(date: Date)
    func cancelTimerNotifications()
    func cancelAlarmNotifications()
}
```

### AudioService
```swift
class AudioService {
    func playAlarmSound(name: String)
    func playTimerEndSound()
    func stopSound()
    func setVolume(_ volume: Float)
}
```

---

## Implementation Phases

### Phase 1: Foundation (2-3 hours)
- [ ] Create Xcode project with iOS and macOS targets
- [ ] Set up SwiftData container
- [ ] Create all data models
- [ ] Build glass effect components
- [ ] Set up notification service
- [ ] Create app constants and formatters

### Phase 2: Calendar (3-4 hours)
- [ ] Month grid view with days
- [ ] Swipe gesture navigation
- [ ] Event model integration
- [ ] Day cell with event indicators
- [ ] Event list for selected date
- [ ] Add/edit event sheet
- [ ] Event CRUD operations

### Phase 3: Timer (3-4 hours)
- [ ] Timer ViewModel with countdown logic
- [ ] Timer display with progress
- [ ] Timer controls (play/pause/reset)
- [ ] Preset grid with buttons
- [ ] Pomodoro timer implementation
- [ ] Background timer with notifications
- [ ] Audio feedback on completion

### Phase 4: Alarm (2-3 hours)
- [ ] Time picker UI
- [ ] Alarm ViewModel
- [ ] Alarm toggle and management
- [ ] Local notifications for alarm
- [ ] Alarm trigger UI (full screen)
- [ ] Snooze functionality
- [ ] Sound selection

### Phase 5: Navigation & Polish (2-3 hours)
- [ ] Adaptive navigation (tab bar / sidebar)
- [ ] Platform-specific layouts
- [ ] Animations and transitions
- [ ] Glass effect theming throughout
- [ ] Accessibility support
- [ ] Dark mode optimization

### Phase 6: Widget (2-3 hours)
- [ ] Widget extension target
- [ ] App groups setup
- [ ] Widget timeline provider
- [ ] Medium widget UI (week + timer/alarm)
- [ ] Large widget UI
- [ ] Data sharing between app and widget
- [ ] Widget configuration

---

## Auto-Commit Workflow

### Commit Strategy
All features and fixes will be automatically committed with the following convention:

**Commit Message Format:**
```
<type>: <description>

[optional body]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `style`: Formatting changes
- `docs`: Documentation updates
- `test`: Test additions/changes

**Examples:**
- `feat: add month swipe navigation to calendar`
- `fix: resolve timer countdown accuracy issue`
- `refactor: extract glass effect modifiers`
- `style: format ViewModels with consistent spacing`

### Commit Frequency
- After completing each significant feature
- After fixing any bug
- After completing each file or component
- Before switching between features

### Commit Process
1. Stage all relevant files
2. Create descriptive commit message
3. Verify commit success
4. Continue with next task

---

## Technical Requirements

### Minimum OS Versions
- iOS 17.0+ (for SwiftData and glass effects)
- macOS 14.0+ (Sonoma)

### Frameworks
- SwiftUI
- SwiftData
- WidgetKit
- UserNotifications
- AVFoundation (audio)
- AppIntents (widget configuration)

### Capabilities
- Background modes: Audio, Background fetch
- Push notifications
- App groups (for widget data sharing)

---

## Testing Checklist

### Calendar
- [ ] Month displays correctly (all days)
- [ ] Swipe changes month
- [ ] Current day highlighted
- [ ] Events display as dots
- [ ] Selecting date shows events
- [ ] Adding event works
- [ ] Editing event works
- [ ] Deleting event works
- [ ] Events persist after app restart

### Timer
- [ ] Timer counts down correctly
- [ ] Play/pause works
- [ ] Reset works
- [ ] Presets set correct duration
- [ ] Background timer continues
- [ ] Notification fires on completion
- [ ] Sound plays on completion
- [ ] Pomodoro cycles correctly
- [ ] Timer persists state

### Alarm
- [ ] Time picker sets correct time
- [ ] Toggle enables/disables alarm
- [ ] Alarm fires at correct time
- [ ] Notification displays correctly
- [ ] Snooze adds correct delay
- [ ] Sound plays
- [ ] Alarm persists after restart

### Widget
- [ ] Medium widget displays week
- [ ] Current day highlighted
- [ ] Timer icon shows when active
- [ ] Alarm icon shows when set
- [ ] Widget updates when data changes
- [ ] Large widget displays correctly

### UI/UX
- [ ] Glass effects render correctly
- [ ] Light/dark mode works
- [ ] iOS layout correct
- [ ] macOS layout correct
- [ ] Animations smooth
- [ ] Accessibility labels present

---

## Future Enhancements

### Version 2.0 Ideas
- Recurring events
- Multiple alarms
- Custom alarm sounds
- Calendar sync (iCloud, Google)
- Widget customization
- Siri shortcuts
- Apple Watch app
- iPad multitasking support

---

## Notes

- Keep all code comment-free as requested
- Use explicit types and access modifiers
- Prefer computed properties over methods for simple logic
- Leverage SwiftUI's declarative syntax
- Test on both iOS and macOS throughout development
- Maintain consistent file organization
- Use preview providers for all views

---

**Total Estimated Time: 14-20 hours**
**Last Updated: 2026-02-04**
