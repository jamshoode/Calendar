import Combine
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
final class StartupManager: ObservableObject {
  @Published public private(set) var isRunning: Bool = false
  @Published public private(set) var progressMessage: String = ""
  @Published public private(set) var timedOut: Bool = false

  private let timeout: TimeInterval
  private var timeoutTask: Task<Void, Never>? = nil
  private var startupTask: Task<Void, Never>? = nil

  // Minimum visible duration for the splash to avoid a quick flicker
  private let minimumDisplayDuration: TimeInterval
  private var startDate: Date?

  /// Inject a shorter timeout for tests. Default timeout = 120s, minimum display = 0.8s.
  init(timeout: TimeInterval = 120, minimumDisplayDuration: TimeInterval = 0.8) {
    self.timeout = timeout
    self.minimumDisplayDuration = minimumDisplayDuration
  }

  deinit {
    timeoutTask?.cancel()
    startupTask?.cancel()
  }

  /// Start the app startup orchestration. Safe to call from the main thread.
  public func start(using context: ModelContext) {
    guard !isRunning else { return }
    isRunning = true
    timedOut = false
    progressMessage = "Preparing…"

    // Start a timeout monitor (sets `timedOut = true` when elapsed)
    timeoutTask = Task { [weak self] in
      guard let self = self else { return }
      do {
        try await Task.sleep(nanoseconds: UInt64(self.timeout * 1_000_000_000))
        await MainActor.run { self.timedOut = true }
      } catch { /* cancelled */  }
    }

    startupTask = Task { [weak self] in
      guard let self = self else { return }

      // Record start time and show initial message.
      self.startDate = Date()
      self.progressMessage = Localization.string(.splashSyncingWidgets)
      if Task.isCancelled { return }

      // Prepare widget payloads from the active app context.
      EventViewModel().syncEventsToWidget(context: context)
      if Task.isCancelled { return }

      // Generate recurring expenses.
      self.progressMessage = Localization.string(.splashGeneratingRecurring)
      RecurringExpenseService.shared.generateRecurringExpenses(context: context)
      if Task.isCancelled { return }

      // Cleanup todos.
      self.progressMessage = Localization.string(.splashCleaningTodos)
      TodoViewModel().cleanupCompletedTodos(context: context)
      TodoViewModel().rescheduleAllNotifications(context: context)
      if Task.isCancelled { return }

      // Refresh FX rates (loads cached rates first, then does a daily network refresh if needed)
      self.progressMessage = Localization.string(.splashRefreshingFX)
      await FXRateService.shared.refreshRatesIfNeeded(context: context)
      if Task.isCancelled { return }

      // Weather refresh.
      self.progressMessage = Localization.string(.splashRefreshingWeather)
      await WeatherViewModel().refreshIfNeeded()
      if Task.isCancelled { return }

      // Monobank sync (non-blocking best effort)
      self.progressMessage = Localization.string(.splashSyncingMonobank)
      await MonobankSyncService.shared.syncIfNeededOnStartup(context: context)
      if Task.isCancelled { return }

      // Calendarific holiday sync: run on new month, or on first configured startup with no local holiday rows.
      if shouldSyncHolidaysOnStartup(context: context) {
        self.progressMessage = Localization.string(.holidaySyncing)
        do {
          try await HolidayService.shared.syncHolidays(context: context)
        } catch {
          ErrorPresenter.presentOnMain(error)
        }
        if Task.isCancelled { return }
      }

      // Google Calendar sync (non-blocking best effort)
      self.progressMessage = "Syncing Google Calendar…"
      await GoogleCalendarSyncService.shared.syncIfNeededOnStartup(context: context)
      if Task.isCancelled { return }

      self.progressMessage = Localization.string(.splashFinalizing)

      // Reload widgets so widget timelines see saved changes.
      WidgetCenter.shared.reloadAllTimelines()

      // Ensure minimum display duration.
      let remainingToShow: TimeInterval
      if let started = self.startDate {
        let elapsed = Date().timeIntervalSince(started)
        let remaining = self.minimumDisplayDuration - elapsed
        remainingToShow = remaining > 0 ? remaining : 0
      } else {
        remainingToShow = 0
      }

      if remainingToShow > 0 {
        try? await Task.sleep(nanoseconds: UInt64(remainingToShow * 1_000_000_000))
      }

      self.timeoutTask?.cancel()
      self.isRunning = false
      self.timedOut = false
      self.progressMessage = ""
      self.startDate = nil
      self.startupTask = nil
    }
  }

  /// Dismiss the blocking UI while letting startup continue in the background.
  public func continueInBackground() {
    // UI-level dismissal only — startup Task continues to completion.
    isRunning = false
  }

  private func shouldSyncHolidaysOnStartup(context: ModelContext) -> Bool {
    let defaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier) ?? .standard
    let source = defaults.string(forKey: Constants.Holiday.sourceKey)
      ?? Constants.Holiday.sourceCalendarific
    guard source == Constants.Holiday.sourceCalendarific else { return false }

    let apiKey = defaults.string(forKey: Constants.Holiday.apiKeyKey)?.trimmingCharacters(
      in: .whitespacesAndNewlines) ?? ""
    let countryCode = defaults.string(forKey: Constants.Holiday.countryCodeKey)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !apiKey.isEmpty, !countryCode.isEmpty else { return false }

    if HolidayService.shared.shouldAutoSync() {
      return true
    }

    var descriptor = FetchDescriptor<Event>(
      predicate: #Predicate { $0.isHoliday == true }
    )
    descriptor.fetchLimit = 1
    let existingHolidays = (try? context.fetch(descriptor)) ?? []
    return existingHolidays.isEmpty
  }
}
