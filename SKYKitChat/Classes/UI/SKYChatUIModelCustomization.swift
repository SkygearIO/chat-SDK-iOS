//
//  SKYChatUIModelCustomization.swift
//  SKYKitChat
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

@objcMembers
public class SKYChatUIModelCustomization: NSObject {
    fileprivate static var sharedInstance: SKYChatUIModelCustomization?

    public fileprivate(set) var userNameField = "username"
    public fileprivate(set) var userAvatarField = "avatar"
}

// MARK: - Singleton
public extension SKYChatUIModelCustomization {

    public static func `default`() -> SKYChatUIModelCustomization {
        if self.sharedInstance == nil {
            self.sharedInstance = SKYChatUIModelCustomization()
        }

        return self.sharedInstance!
    }
}

// MARK: - User Configuration
public extension SKYChatUIModelCustomization {
    public func update(userNameField field: String) -> SKYChatUIModelCustomization {
        self.userNameField = field
        return self
    }

    public func update(userAvatarField field: String) -> SKYChatUIModelCustomization {
        self.userAvatarField = field
        return self
    }
}
