## 1.6.2 (2018-08-23)

### Features

- Add fetchConversationsWithPage api that support paging (#226)

### Bug Fixes

- Fix save conversation exception
- Fix SKYConversation deserialization error
- Synchronize the send button state with input text view

### Other Notes

- Update SVProgressHUD

## 1.5.1 (2018-07-11)

### Other Notes

- Update podspec to require SKYKit/Core version ~> 1.4, so that user can update core sdk with newer minor version.

## 1.5.0 (2018-05-16)

### Features

    - API updates:
        - Update fetchMessages api with cache support
        - Introduce message operation cache objects for fail operation handling
        - Implement fetch participant API with cache enabled #196 #197 #198 #203
        - Support beforeMessageID parameter for query messages #175
    - UIKit updates:
        - Support UI and Text customization support in SKYChatConversationViewController
            - Support showing username list as conversation view title #80
            - Provide more customization on text on conversation view #39
            - Add more UI customization on conversation view #103
            - Add capability to turn off some features in conversation view #103
        - Add event hooks for conversation view #103 #148 #218
        - Show placeholder during avatar loading state #216
        - Disable highlighting text in message cell in JSQMessagesViewController-Skygear v7.3.5.4

### Bug Fixes

    - API updates:
        - Add missing adminIDs to options when calling chat:create_conversation SkygearIO/chat#192
    - UIKit updates:
        - For sending image message, update SKYKit to 1.3.1 with fail to init asset fixes
        - Fix scroll position of conversation view
        - Fix some minor issues in UIKit #194 #195
        - Fix voice message related issues #207 #210
        - Touch message list blank area should dismiss keyboard #40
        - iPhone X support #141
        - The chat view shifted to the top crash the layout when back from another view controller #143

### Other Notes

    - Support Swift 4 #101
    - Update APIs written in Objective-C to assume nonnullability #184
    - Build Swift Example in travis
    - Use Published JSQMessagesViewController-Skygear pod
    - Make unnecessary properties to private #217
    - Add back `@objc` decorator to all public classes in Swift

