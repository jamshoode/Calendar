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
- Step 2/25: Google Calendar V1 implementation skeleton aligned to app architecture.
- Step 3/25: Added persistent Google connection model and app model registration.
- Step 4/25: Added per-calendar sync state model for token-driven incremental sync.
- Step 5/25: Added Google constants and integration-level defaults.
- Step 6/25: Registered GoogleSignIn package dependency for the app target.
- Step 7/25: Added Google metadata fields to events for sync mapping.
- Step 8/25: Added Google metadata fields to todos for all-day event mapping.
- Step 9/25: Added keychain-backed token storage with load/save/delete contract.
- Step 10/25: Added Google auth coordinator and URL callback handling.
- Step 11/25: Added Google Calendar DTO models for calendars/events/upsert payloads.
- Step 12/25: Added Google Calendar API client with error mapping and retry policy.
- Step 13/25: Added calendar discovery service for user-selectable calendar list.
- Step 14/25: Added sync service full/incremental flows with token persistence.
- Step 15/25: Added 410 sync-token invalidation recovery flow.
- Step 16/25: Added outbound event create/update/delete hooks to sync service.
- Step 17/25: Added outbound todo all-day mapping and delete-on-no-due-date behavior.
- Step 18/25: Applied explicit Google-wins conflict policy in merge decisions.
- Step 19/25: Added settings UI for connect/disconnect/manual sync/calendar selection.
- Step 20/25: Added startup sync trigger with throttled best-effort behavior.
- Step 21/25: Added foreground active trigger for safe incremental refresh.
- Step 22/25: Added Google holiday source migration and Calendarific disablement path.
- Step 23/25: Added Google core unit tests for DTO decoding and API error/retry behavior.
- Step 24/25: Added sync integration tests for full/incremental/410/conflict/todo round-trip.
- Step 25/25: Final verification and tracker completion.

## Verification

- Added new test files to `CalendarTests` target in the Xcode project for each test step.
- Verified step-scoped commits exist through step 25 with one commit per step.
- Attempted targeted xcodebuild test execution for Google test classes using workspace scheme.
- Current workspace has pre-existing compile errors in Google integration source files that block test execution in this environment; these are tracked as existing issues outside this final tracker update step.
