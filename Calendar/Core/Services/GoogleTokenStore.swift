import Foundation
import Security

struct GoogleOAuthTokens: Codable {
  let accessToken: String
  let refreshToken: String
  let expirationDate: Date
}

protocol GoogleTokenStore {
  func saveTokens(_ tokens: GoogleOAuthTokens) throws
  func loadTokens() throws -> GoogleOAuthTokens?
  func deleteTokens() throws
}

final class GoogleKeychainStore: GoogleTokenStore {
  static let shared = GoogleKeychainStore()

  private let service = "com.shoode.calendar.googlecalendar"
  private let account = "oauth-tokens"

  private init() {}

  func saveTokens(_ tokens: GoogleOAuthTokens) throws {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    let data: Data
    do {
      data = try encoder.encode(tokens)
    } catch {
      throw GoogleSecurityError.invalidTokenData
    }

    try deleteTokens()

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw GoogleSecurityError.keychainSaveFailed(status)
    }
  }

  func loadTokens() throws -> GoogleOAuthTokens? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw GoogleSecurityError.keychainReadFailed(status)
    }

    guard let data = item as? Data else {
      throw GoogleSecurityError.invalidTokenData
    }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      return try decoder.decode(GoogleOAuthTokens.self, from: data)
    } catch {
      throw GoogleSecurityError.invalidTokenData
    }
  }

  func deleteTokens() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw GoogleSecurityError.keychainDeleteFailed(status)
    }
  }
}

enum GoogleSecurityError: LocalizedError {
  case keychainSaveFailed(OSStatus)
  case keychainReadFailed(OSStatus)
  case keychainDeleteFailed(OSStatus)
  case invalidTokenData

  var errorDescription: String? {
    switch self {
    case .keychainSaveFailed(let status):
      return "Failed to save Google OAuth tokens (\(status))."
    case .keychainReadFailed(let status):
      return "Failed to read Google OAuth tokens (\(status))."
    case .keychainDeleteFailed(let status):
      return "Failed to delete Google OAuth tokens (\(status))."
    case .invalidTokenData:
      return "Google OAuth token data is invalid."
    }
  }
}
