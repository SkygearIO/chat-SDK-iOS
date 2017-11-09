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

public enum AvatarType {
    case asset
    case urlString
}

public class SKYChatUIModelCustomization {
    fileprivate static var sharedInstance: SKYChatUIModelCustomization? = nil

    public fileprivate(set) var userNameField = "username"
    public fileprivate(set) var userAvatarField = "avatar"
    public fileprivate(set) var userAvatarType = AvatarType.asset
}

// MARK: - Singleton
public extension SKYChatUIModelCustomization {

    static func `default`() -> SKYChatUIModelCustomization {
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
        return self.update(userAvatarField: field, avatarType: self.userAvatarType)
    }

    public func update(userAvatarField field: String,
                       avatarType type: AvatarType) -> SKYChatUIModelCustomization
    {
        self.userAvatarField = field
        self.userAvatarType = type
        return self
    }
}
