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

import JSQMessagesViewController

@objc public enum SKYChatConversationViewUserAvatarType: Int {
    case initial
    case image
}

@objc public enum SKYChatConversationViewTitleOptions: Int {
    /**
     Showing the title of the conversation for conversation view
     */
    case `default`

    /**
     Showing the list of other participants name
     */
    case otherParticipants
}

public class SKYChatConversationViewTextCustomization {

    public var sendButton = NSLocalizedString("Send", comment: "")

    public var messageSentFailed = NSLocalizedString("Failed", comment: "")

    public var messageStatusAllRead = NSLocalizedString("All read", comment: "")
    public var messageStatusSomeRead = NSLocalizedString("Some read", comment: "")
    public var messageStatusDelivered = NSLocalizedString("Delivered", comment: "")
    public var messageStatusDelivering = NSLocalizedString("Delivering", comment: "")

    public func getMessageStatus(_ status: SKYMessageConversationStatus) -> String {
        switch status {
        case .allRead: return messageStatusAllRead
        case .someRead: return messageStatusSomeRead
        case .delivered: return messageStatusDelivered
        case .delivering: return messageStatusDelivering
        }
    }
}

public class SKYChatConversationViewCustomization {
    static var sharedInstance: SKYChatConversationViewCustomization?

    public var titleDisplayType: SKYChatConversationViewTitleOptions = .`default`
    public var avatarBackgroundColor: UIColor?
    public var avatarTextColor: UIColor?
    public var messageSenderTextColor: UIColor?
    public var avatarType: SKYChatConversationViewUserAvatarType = .initial
    public var avatarHiddenForOutgoingMessages: Bool = false
    public var avatarHiddenForIncomingMessages: Bool = false
    public var avatarHidden: Bool? {
        get {
            if self.avatarHiddenForIncomingMessages == self.avatarHiddenForOutgoingMessages {
                return self.avatarHiddenForOutgoingMessages
            }

            return nil
        }
        set {
            if let hidden = newValue {
                self.avatarHiddenForIncomingMessages = hidden
                self.avatarHiddenForOutgoingMessages = hidden
            }
        }
    }

    public lazy var textCustomization: SKYChatConversationViewTextCustomization
        = SKYChatConversationViewTextCustomization()

    public var messageDateFormatter: DateFormatter

    public var backgroundColor: UIColor = UIColor.white
    public var backgroundImage: UIImage?
    public var backgroundImageURL: NSURL?

    public var cameraButtonShouldShow: Bool = true
    public var voiceMessageButtonShouldShow: Bool = true
    public var typingIndicatorShouldShow: Bool = true
    public var messageStatusShouldShow: Bool = true

    public var messageTimestampTextColor: UIColor = UIColor.gray
    public var messageStatusTextColor: UIColor = UIColor.lightGray
    public var incomingMessageBubbleColor: UIColor = UIColor.lightGray
    public var outgoingMessageBubbleColor: UIColor = UIColor.jsq_messageBubbleBlue()
    public var incomingMessageTextColor: UIColor = UIColor.white
    public var outgoingMessageTextColor: UIColor = UIColor.white
    public var incomingAudioMessageButtonColor: UIColor = UIColor.white
    public var outgoingAudioMessageButtonColor: UIColor = UIColor.jsq_messageBubbleBlue()

    init() {
        self.messageDateFormatter = {
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .short
            df.doesRelativeDateFormatting = true
            return df
        }()
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
