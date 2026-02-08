#if os(iOS)
  import UIKit
  import SwiftUI
  import UserNotifications

  class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
      _ application: UIApplication,
      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
      NotificationService.shared.requestAuthorization()

      // Dark blue-black background beneath all SwiftUI content
      let bgColor = UIColor(Color.darkBackground)
      UIWindow.appearance().backgroundColor = bgColor

      // Match navigation bar backgrounds
      let navAppearance = UINavigationBarAppearance()
      navAppearance.configureWithOpaqueBackground()
      navAppearance.backgroundColor = bgColor
      UINavigationBar.appearance().standardAppearance = navAppearance
      UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

      return true
    }

    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
    }

    func application(
      _ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      // print("Failed to register for remote notifications: \(error)")
    }
  }
#endif
