# Plan: Complete App Redesign — Neutral Chrome, Color-as-Content

**TL;DR:** Rebuild the visual layer from the ground up with a monochromatic design system that uses system-adaptive colors (dark grays in dark mode, whites in light mode). All UI chrome is neutral — color appears ONLY in event dots, category labels, status badges, and expense categories. Navigation consolidates to 4 tabs (Calendar, Tasks, Expenses, Clock). Calendar gets 3 toggleable views (grid, list, timeline). Expenses is a full new feature. Timer + Alarm merge. The data layer and services stay intact; this is primarily a UI/design-system rewrite touching ~40 files.

**Steps**

## Phase 0: Cleanup

1. Delete the 5 style experiment branches (`style/flat-dark`, `style/gradient-cards`, `style/elevated-surfaces`, `style/minimal-borderless`, `style/hybrid-glass`)
2. Delete stale `Calendar/Widget/CalendarWidget.swift` (legacy duplicate with wrong App Group ID)
3. Delete duplicate `App/AppState.swift` at project root
4. Remove UIAppearance hacks from `AppDelegate.swift` (dark background customizations) — will use system colors instead

## Phase 1: Design System Foundation

5. Rewrite `Color+Glass.swift` → rename to `Color+Theme.swift` — define system-adaptive design tokens:
   - `Color.backgroundPrimary` → `.systemBackground`
   - `Color.backgroundSecondary` → `.secondarySystemBackground`
   - `Color.surfaceCard` → `.secondarySystemGroupedBackground`
   - `Color.textPrimary` → `.label`
   - `Color.textSecondary` → `.secondaryLabel`
   - `Color.textTertiary` → `.tertiaryLabel`
   - `Color.border` → `.separator`
   - Keep the 8 event colors (blue, green, orange, red, purple, pink, yellow, teal) — these are the only custom colors
   - Add expense category colors and status badge colors
6. Create `Typography.swift` — define a consistent type scale:
   - `largeTitle`: 28pt bold (screen titles like "February 2026")
   - `title`: 20pt semibold (section headers)
   - `headline`: 16pt semibold (event names, card titles)
   - `body`: 15pt regular (descriptions, notes)
   - `caption`: 12pt regular (timestamps, secondary info)
   - `badge`: 11pt medium (status badges, counts)
7. Create `Spacing.swift` — standardized spacing tokens (4, 8, 12, 16, 20, 24, 32) referenced everywhere instead of hardcoded values
8. Rewrite `GlassBackground.swift` → rename to `CardStyle.swift` — flat solid surfaces using `Color.surfaceCard` with `Color.border` strokes, no materials
9. Rewrite `GlassCard.swift` → adapt to new `CardStyle`
10. Rewrite `GlassButton.swift` → neutral solid button, accent-colored for primary actions only
11. Rewrite `View+Glass.swift` → rename to `View+Theme.swift`, strip all material references
12. Create `StatusBadge.swift` — reusable colored pill component for task statuses (Completed=green, In Progress=orange, Queued=gray) — inspired by Image 5 right panel

## Phase 2: Navigation Restructure

13. Rewrite `AppState.swift` — change tabs to `.calendar`, `.tasks`, `.expenses`, `.clock`
14. Rewrite `AdaptiveTabBar.swift` — 4 tabs with system tab bar styling (no UIAppearance hacks), icons: `calendar`, `checkmark.circle`, `dollarsign.circle`, `clock`
15. Rewrite `TopBarView.swift` — remove hamburger menu, add per-screen contextual actions (view toggle for Calendar, filter for Tasks, period picker for Expenses, none for Clock)
16. Rewrite `SideSheetModifier.swift` — Settings moves from side sheet to a standard `.sheet` or `.navigationDestination` push, using system presentation instead of custom overlay

## Phase 3: Calendar Redesign (3 toggleable views)

17. Rewrite `CalendarView.swift` — add `@State var viewMode: CalendarViewMode` enum (`.grid`, `.list`, `.timeline`) with 3 toggle icons in header (grid.fill, list.bullet, clock.fill)
18. Rewrite `MonthHeaderView` (in CalendarView.swift) — large left-aligned "February 2026" title (like Image 2), view mode toggle icons at right
19. Keep `MonthView.swift` as the `.grid` mode — clean up with neutral colors, system-adaptive backgrounds
20. Create `CalendarListView.swift` — the `.list` mode inspired by Images 6 (right panel) and 9: scrollable vertical list with date column on left (Feb 26 Saturday, Feb 27 Sunday…) and colored event cards on right
21. Create `CalendarTimelineView.swift` — the `.timeline` mode inspired by Image 5 left: horizontal week strip at top (M T W T F S S with date numbers), then vertical hourly axis (7 AM – 11 PM) with event blocks positioned by time
22. Create `WeekStrip.swift` — reusable horizontal week day selector used in timeline view and potentially expenses
23. Rewrite `EventListView.swift` — the event list below the grid; cleaner with colored left-border bars for events (like Image 6 left), status info, "Today" section header
24. Rewrite `EventDetailPopover.swift` — convert from glass floating card to clean push/sheet detail view (like Image 5 center + Image 1 right): title, date/time, description, colored category bar, edit/delete actions
25. Rewrite `DayCell.swift` — neutral background with colored event dots, today highlight with simple circle, no glass
26. Rewrite `AddEventView.swift` — stacked label/value layout (like Image 7): TITLE, DATE AND TIME, DESCRIPTION, COLOR, REMINDER — clean field styling
27. Rewrite `MonthYearPicker.swift` — cleaner picker with system-adaptive styling

## Phase 4: Tasks Redesign

28. Rewrite `TodoView.swift` — new layout inspired by Image 5 right panel:
    - Search bar at top
    - Summary cards row (Status count, Due Date)
    - Segmented filter: All Tasks / Queued / Completed
    - Task rows with colored status badges
    - Category cards with progress bars (Image 8 style)
    - FAB for adding
29. Rewrite `TodoRow.swift` — horizontal: checkbox + title/subtitle + status badge pill on right
30. Rewrite `CategoryCard.swift` — progress bar at top (Image 8), expandable with smooth animation
31. Rewrite `AddTodoSheet.swift` — stacked label/value pairs (Image 7 style): TASK, DUE BY, LIST, PRIORITY, NOTES — clean minimal spacing
32. Rewrite `PriorityBadge.swift` — consolidate all priority color definitions to one source of truth

## Phase 5: Expenses Feature (New)

33. Create `Expense.swift` model — SwiftData `@Model` with: `id`, `title`, `amount: Decimal`, `date`, `category: ExpenseCategory`, `paymentMethod` (cash/card enum), `merchant`, `notes`, `createdAt`
34. Create `ExpenseCategory.swift` enum — predefined categories: Groceries, Housing, Transportation, Subscriptions, Healthcare, Debt Payments, etc. Each has icon (SF Symbol) + default color
35. Create `ExpenseViewModel.swift` — CRUD, aggregation (weekly/monthly/yearly totals, per-category totals, daily totals for heatmap)
36. Create `ExpensesView.swift` — main expenses tab inspired by Image 4:
    - Period segmented control: Weekly / Monthly / Yearly
    - Calendar/week view showing spending per day (colored intensity like Image 4 left)
    - Total amount displayed prominently
    - Below: scrollable expense list grouped by date, with category icon + title + merchant + amount + payment badge
37. Create `AddExpenseSheet.swift` — clean stacked fields: TITLE, AMOUNT, DATE, CATEGORY (picker), MERCHANT, PAYMENT METHOD (segmented: Cash/Card), NOTES
38. Create `ExpenseRow.swift` — category icon + title + merchant subtitle + right-aligned amount + payment badge
39. Create `ExpenseCalendarView.swift` — month/week grid where days are colored by spending intensity (green→yellow→red gradient based on daily total)
40. Add expense localization keys to `Localization.swift`

## Phase 6: Clock (Merged Timer + Alarm)

41. Create `ClockView.swift` — single view combining timer and alarm, with two sections:
    - **Timer section**: segmented Countdown/Pomodoro toggle, circular progress, controls
    - **Alarm section**: alarm time display + toggle + edit
    - Clean separation via section headers
42. Adapt `TimerView.swift` → `TimerSection.swift` — embedded component, not a full tab
43. Adapt `AlarmView.swift` → `AlarmSection.swift` — embedded component
44. Rewrite `TimerDisplay.swift` — fix hardcoded 3600s total duration, use system-adaptive colors for the ring
45. Rewrite `TimerControls.swift` — neutral button backgrounds instead of material

## Phase 7: Settings

46. Rewrite `SettingsSheet.swift` — standard sheet presentation (not side sheet), show all settings regardless of active tab, add Expenses settings section, grouped list style matching system Settings look

## Phase 8: Widget Update

47. Update `CalendarWidget/CalendarWidget.swift` — adapt color scheme to match new neutral design tokens, support both light and dark properly, update event display to match new color-as-content approach

## Phase 9: Cleanup & Polish

48. Delete files no longer needed: `GlassBackground.swift`, `GlassCard.swift`, old glass references
49. Fix all audit issues: consolidate priority colors, remove unused `TimerSession` model from schema, fix hardcoded strings in TimePicker, add proper localization keys for new features
50. Update `project.pbxproj` — register all new files, remove deleted files

## Verification

- Build and run on iOS simulator — verify all 4 tabs render correctly in both light and dark mode
- Toggle between calendar views (grid/list/timeline)
- Create, edit, delete events and confirm detail view works
- Create, edit, delete tasks with status badges and category progress
- Create, edit expenses and verify weekly/monthly/yearly summaries
- Test timer countdown + pomodoro + alarm in Clock tab
- Test widget appearance in both color schemes
- Verify holiday sync still works
- Switch between light/dark mode to confirm all surfaces adapt

## Key Decisions

- Chose monochromatic chrome over any colored theme — color is exclusively for content (events, statuses, categories)
- Using `UIColor` system adaptive colors (`.systemBackground`, `.label`, `.separator`) instead of custom RGB — automatic light/dark support with zero conditional logic
- Calendar gets 3 toggleable views rather than forcing one layout
- Timer + Alarm merge into "Clock" tab rather than keeping 5 tabs
- Settings moves from custom side sheet to standard system `.sheet`
- No glass/material anywhere — flat solid surfaces with system colors
- Event detail moves from floating popover to standard navigation/sheet pattern
