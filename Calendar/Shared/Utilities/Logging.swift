import os

struct Logging {
  static let subsystem = Bundle.main.bundleIdentifier ?? "com.shoode.calendar"
  static let log = Logger(subsystem: subsystem, category: "app")
}
