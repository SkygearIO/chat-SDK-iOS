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

open class SKYChatConversationView: JSQMessagesCollectionView {
    @objc dynamic public var avatarBackgroundColor: UIColor?
    @objc dynamic public var avatarTextColor: UIColor?
    @objc dynamic public var messageSenderTextColor: UIColor?
    @objc dynamic public var avatarHiddenForOutgoingMessages: Bool = false
    @objc dynamic public var avatarHiddenForIncomingMessages: Bool = false
    @objc dynamic public var avatarHidden: Bool = false {
        didSet {
            self.avatarHiddenForIncomingMessages = self.avatarHidden
            self.avatarHiddenForOutgoingMessages = self.avatarHidden
        }
    }
}
