import Foundation
import SwiftData

#if os(iOS)
  import GoogleSignIn
  import UIKit

  struct GoogleAccountProfile {
    let email: String?
    let displayName: String?
  }

  enum GoogleAuthError: LocalizedError {
    case missingClientId
    case invalidClientId
    case signInFailed
    case missingRefreshToken
    case missingAccessToken

    var errorDescription: String? {
      switch self {
      case .missingClientId:
        return
          "Missing Google client ID. Set GIDClientID in Info.plist or add GoogleService-Info.plist with CLIENT_ID."
      case .invalidClientId:
        return
          "Google client ID is invalid. Expected value ending with .apps.googleusercontent.com."
      case .signInFailed:
        return "Google sign-in failed."
      case .missingRefreshToken:
        return "Google sign-in did not return a refresh token."
      case .missingAccessToken:
        return "Google sign-in did not return an access token."
      }
    }
  }

  @MainActor
  final class GoogleAuthCoordinator {
    static let shared = GoogleAuthCoordinator()

    private let tokenStore: GoogleTokenStore

    private init() {
      self.tokenStore = GoogleKeychainStore.shared
    }

    init(tokenStore: GoogleTokenStore) {
      self.tokenStore = tokenStore
    }

    func configure() throws {
      guard let clientId = resolveClientID() else {
        throw GoogleAuthError.missingClientId
      }

      guard Self.isValidClientID(clientId) else {
        throw GoogleAuthError.invalidClientId
      }

      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    private func resolveClientID() -> String? {
      if let configured = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
        !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        return configured
      }

      guard
        let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
        let data = try? Data(contentsOf: url),
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
          as? [String: Any],
        let clientID = plist["CLIENT_ID"] as? String,
        !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        return nil
      }

      return clientID
    }

    private static func isValidClientID(_ value: String) -> Bool {
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.contains(".apps.googleusercontent.com")
        && !trimmed.contains("$(")
    }

    func handle(url: URL) -> Bool {
      GIDSignIn.sharedInstance.handle(url)
    }

    func restorePreviousSignIn() async -> GoogleAccountProfile? {
      do {
        try configure()
      } catch {
        return nil
      }

      do {
        let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        return try persistSession(user: user)
      } catch {
        return nil
      }
    }

    func signIn(with presentingViewController: UIViewController) async throws
      -> GoogleAccountProfile
    {
      try configure()

      let result = try await GIDSignIn.sharedInstance.signIn(
        withPresenting: presentingViewController,
        hint: nil,
        additionalScopes: Constants.GoogleCalendar.defaultScopes
      )
      return try persistSession(user: result.user)
    }

    func signOut() {
      GIDSignIn.sharedInstance.signOut()
      try? tokenStore.deleteTokens()
    }

    func disconnect() {
      GIDSignIn.sharedInstance.disconnect { _ in }
      try? tokenStore.deleteTokens()
    }

    @discardableResult
    private func persistSession(user: GIDGoogleUser) throws -> GoogleAccountProfile {
      let accessToken = user.accessToken.tokenString
      guard !accessToken.isEmpty else {
        throw GoogleAuthError.missingAccessToken
      }

      let refreshToken = user.refreshToken.tokenString
      guard !refreshToken.isEmpty else {
        throw GoogleAuthError.missingRefreshToken
      }

      guard let expirationDate = user.accessToken.expirationDate else {
        throw GoogleAuthError.signInFailed
      }
      let tokens = GoogleOAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expirationDate: expirationDate
      )
      try tokenStore.saveTokens(tokens)

      return GoogleAccountProfile(
        email: user.profile?.email,
        displayName: user.profile?.name
      )
    }
  }

#else

  struct GoogleAccountProfile {
    let email: String?
    let displayName: String?
  }

  @MainActor
  final class GoogleAuthCoordinator {
    static let shared = GoogleAuthCoordinator()

    private init() {}

    func handle(url: URL) -> Bool {
      false
    }

    func restorePreviousSignIn() async -> GoogleAccountProfile? {
      nil
    }

    func signOut() {}
    func disconnect() {}
  }

#endif
