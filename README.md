# SKYKitChat

[![CI Status](https://img.shields.io/travis/SkygearIO/chat-SDK-iOS.svg?style=flat)](https://travis-ci.org/SkygearIO/chat-SDK-iOS)
[![Version](https://img.shields.io/cocoapods/v/SKYKitChat.svg?style=flat)](http://cocoapods.org/pods/SKYKitChat)
[![License](https://img.shields.io/cocoapods/l/SKYKitChat.svg?style=flat)](http://cocoapods.org/pods/SKYKitChat)
[![Platform](https://img.shields.io/cocoapods/p/SKYKitChat.svg?style=flat)](http://cocoapods.org/pods/SKYKitChat)


## Using Skygear Chat iOS SDK

Please reference to Skygear Chat Quick Start guide for how to use `SKYKitChat`: https://docs.skygear.io/guides/chat/quick-start/ios/

## Using Skygear Chat UIKit

UIKit only support Swift 3.2 for now. Swift 4.0 supports are coming.

To use the UIKit comes with Skygear, follow these steps:

### 1. Include `SKYKitChat/UI` in PodFile

```
  pod 'SKYKit', '~> 1.1'
  pod 'SKYKitChat', '~> 1.1'
  pod 'SKYKitChat/UI', '~> 1.1'
```

Run `pod install` afterwards

### 2. Include 3 permissions by adding 3 rows in `Info.plist` of your XCode project:

* `Privacy - Photo Library Usage Description`
  * Recommended Description: The app requires access to your photo library for sending images in chat
* `Privacy - Camera Usage Description`
  * Recommended Description: The app requires access to your camera for sending images in chat
* `Privacy - Microphone Usage Description`
  * Recommended Description: The app requires access to your microphone for sending voices in chat

### 3. Open conversation view after creating conversation object

Currently UIKit consist of a built-in conversation view. You can use it after getting the
conversation object from Chat API:

```swift
let vc = SKYChatConversationViewController()
vc.conversation = conversation // conversation object create from chat sdk
self.navigationController?.pushViewController(vc, animated: true)
```

### Bare minimal sample
A bare minimal example in Swift 3.2, which will display a SKYChatConversationView without the
navigation bar, to chat with a User hard-coded its ID.

`AppDelegate.swift`:

```swift
import UIKit
import SKYKit
import SKYKitChat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let skygear = SKYContainer.default()

        skygear.configAddress("change me with your Skygear API Endpoint")
        skygear.configure(withAPIKey: "change me with your Skygear API Key")

        skygear.auth.signupAnonymously(completionHandler: { (user, error) in
            skygear.chatExtension?.createDirectConversation(userID: "change me with a user ID in your app", title: "Test Group", metadata: nil, completion: { (conversation, error) in
                let vc = SKYChatConversationViewController()
                vc.conversation = conversation
                self.window?.rootViewController = vc
            })
        })
        return true
    }
```

If you project is in Objective-C, and you need to use the UI classes, you need
to add the generated interface header:

```objective-c
#import <SKYKitChat/SKYKitChat-Swift.h>
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## License

SKYKitChat is available under the Apache License, Version 2.0. See the LICENSE file for more info.
