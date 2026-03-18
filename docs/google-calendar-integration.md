# Google Calendar Integration Tracker

This document tracks the implementation of Google Calendar V1 integration.

## Scope

- Platform: iOS first
- Sync: Two-way sync
- Account model: Single Google account
- Calendars: User-selected calendars
- Conflict policy: Google wins
- Entities in V1:
  - Events
  - Todo items with due dates (mapped as all-day events)
  - Holidays (Google calendar based)

## Delivery Protocol

- Execute in 25 implementation steps.
- Create one git commit per step.
- Do not amend commits.
- For every new file, add it to Xcode project when needed.

## Step Log

- Step 1/25: Branch created and tracker initialized.
