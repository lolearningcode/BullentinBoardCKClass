//
//  AppDelegate.swift
//  BullentinBoardCloudKitClass
//
//  Created by Lo Howard on 6/3/19.
//  Copyright © 2019 Lo Howard. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    static let messageNotification = Notification.Name("MessageNotification")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (userDidAuthorize, error) in
            if let error = error {
                print("🤬\(error.localizedDescription)")
            }
            
            guard userDidAuthorize else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        MessageController.shared.subscribeToNotifications { (error) in
            if let error = error {
                print("Error subscribing \(error.localizedDescription)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        MessageController.shared.fetchMessages { (success) in
            if success {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: AppDelegate.messageNotification, object: self)
                }
            }
        }
    }
}

