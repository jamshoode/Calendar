import Foundation

// Lightweight error broadcaster — posts notifications so UI can react across threads.
final class ErrorPresenter {
  static let shared = ErrorPresenter()

  func present(_ error: Error) {
    present(message: error.localizedDescription)
  }

  func present(message: String) {
    NotificationCenter.default.post(
      name: .appErrorOccurred, object: nil, userInfo: ["message": message]
    )
  }

  nonisolated static func presentOnMain(_ error: Error) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: .appErrorOccurred, object: nil, userInfo: ["message": error.localizedDescription]
      )
    }
  }

  nonisolated static func presentOnMain(message: String) {
    DispatchQueue.main.async {
      NotificationCenter.default.post(
        name: .appErrorOccurred, object: nil, userInfo: ["message": message]
      )
    }
  }
}
