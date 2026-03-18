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
    case signInFailed
    case missingRefreshToken
    case missingAccessToken

    var errorDescription: String? {
      switch self {
      case .missingClientId:
        return "Missing GIDClientID in Info.plist."
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

    private init(tokenStore: GoogleTokenStore = GoogleKeychainStore.shared) {
      self.tokenStore = tokenStore
    }

    func configure() throws {
      guard
        let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
        !clientId.isEmpty
      else {
        throw GoogleAuthError.missingClientId
      }

      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
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

    func signIn(with presentingViewController: UIViewController) async throws -> GoogleAccountProfile {
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
      guard let accessToken = user.accessToken.tokenString else {
        throw GoogleAuthError.missingAccessToken
      }

      guard let refreshToken = user.refreshToken.tokenString else {
        throw GoogleAuthError.missingRefreshToken
      }

      let expirationDate = user.accessToken.expirationDate
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
