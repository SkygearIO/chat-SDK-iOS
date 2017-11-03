//
//  AppDelegate.swift
//  Swift-Example
//
//  Copyright 2016 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import SKYKit
import SKYKitChat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var skygear: SKYContainer {
        return SKYContainer.default()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        if let endpointValue = UserDefaults.standard.string(forKey: "SkygearEndpoint") {
            self.skygear.configAddress(endpointValue)
        }
        if let apiKeyValue = UserDefaults.standard.string(forKey: "SkygearApiKey") {
            self.skygear.configure(withAPIKey: apiKeyValue)
        }

        self.skygear.push.registerDeviceCompletionHandler { (deviceID, error) in
            guard error == nil else {
                print("Got error when register device: \(error!.localizedDescription)")
                return
            }

            if let id = deviceID {
                print("Registered device with ID: \(id)")
            } else {
                print("Got nil device ID")
            }
        }

        application.registerUserNotificationSettings(UIUserNotificationSettings.init(
            types: [.alert, .badge, .sound],
            categories: nil
        ))

        let _ = SKYChatUIModelCustomization.default()
            .update(userNameField: "name")
            .update(userAvatarField: "profile_pic", avatarType: .URLString)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        guard !notificationSettings.types.isEmpty else {
            print("User does not allow notification")
            return
        }

        application.registerForRemoteNotifications()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Got remote notification device token")
        self.skygear.push.registerDevice(withDeviceToken: deviceToken) {(_, error) in
            guard error == nil else {
                print("Got error when register push notification token: \(error!.localizedDescription)")
                return
            }

            print("Successfully registered push notification token")
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fail to get remote notification device token: \(error.localizedDescription)")
    }
}
