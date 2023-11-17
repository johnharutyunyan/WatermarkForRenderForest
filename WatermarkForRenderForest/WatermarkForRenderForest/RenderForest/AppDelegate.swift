//
//  AppDelegate.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 11.11.23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    // MARK: - Property
    var window: UIWindow?
    private var applicationStartController: ApplicationStartController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension UIApplication {
    var keyWindow: UIWindow? {
          // Get connected scenes
          return self.connectedScenes
              // Keep only active scenes, onscreen and visible to the user
              .filter { $0.activationState == .foregroundActive }
              // Keep only the first `UIWindowScene`
              .first(where: { $0 is UIWindowScene })
              // Get its associated windows
              .flatMap({ $0 as? UIWindowScene })?.windows
              // Finally, keep only the key window
              .first(where: \.isKeyWindow)
      }
}
