//
//  SKYChatConversationView.swift
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

@objc public enum SKYChatConversationViewUserAvatarType: Int {
    case initial
    case image
}

public class SKYChatConversationViewCustomization {
    static var sharedInstance: SKYChatConversationViewCustomization? = nil

    public var avatarBackgroundColor: UIColor?
    public var avatarTextColor: UIColor?
    public var messageSenderTextColor: UIColor?
    public var avatarType: SKYChatConversationViewUserAvatarType = .initial
    public var avatarHiddenForOutgoingMessages: Bool = false
    public var avatarHiddenForIncomingMessages: Bool = false
    public var avatarHidden: Bool = false {
        didSet {
            self.avatarHiddenForIncomingMessages = self.avatarHidden
            self.avatarHiddenForOutgoingMessages = self.avatarHidden
        }
    }

    public static func `default`() -> SKYChatConversationViewCustomization {
        if self.sharedInstance == nil {
            self.sharedInstance = SKYChatConversationViewCustomization()
        }

        return self.sharedInstance!
    }
}

open class SKYChatConversationView: JSQMessagesCollectionView {
    public static func UICustomization() -> SKYChatConversationViewCustomization {
         return SKYChatConversationViewCustomization.default()
    }
}
