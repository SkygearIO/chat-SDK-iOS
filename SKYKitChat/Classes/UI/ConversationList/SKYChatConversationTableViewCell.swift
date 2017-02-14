//
//  SKYChatConversationTableViewCell.swift
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

open class SKYChatConversationTableViewCell: UITableViewCell {
    let untitledConversation: String = "Untitled Conversation"

    public var conversation: SKYConversation?
    public var participants: [SKYRecord] = []
    public var conversationMessage: String?
    public var conversationInformation: String?
    public var unreadMessageCount: Int?
    public var avatarImage: UIImage?

    @IBOutlet public weak var avatarImageView: UIImageView!
    @IBOutlet public weak var conversationTitleLabel: UILabel!
    @IBOutlet public weak var conversationMessageLabel: UILabel!
    @IBOutlet public weak var conversationInformationLabel: UILabel!
    @IBOutlet public weak var unreadCountLabel: UILabel!
    @IBOutlet public weak var unreadCountView: UIView!

    public class var nib: UINib {
        return UINib(nibName: "SKYChatConversationTableViewCell",
                      bundle: Bundle(for: SKYChatConversationTableViewCell.self))
    }

    open override func awakeFromNib() {
        if let img = self.avatarImageView {
            img.layer.cornerRadius = CGFloat(0.5 * img.frame.height)
        }

        if let view = self.unreadCountView {
            view.layer.cornerRadius = CGFloat(0.5 * view.frame.height)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // avatar image
        if let img = self.avatarImage {
            self.avatarImageView?.image = img
        } else {
            self.avatarImageView?.removeFromSuperview()
        }

        if let conv = self.conversation {
            self.layoutSubviews(conversation: conv)
        } else {
            self.conversationTitleLabel?.text = untitledConversation
            self.conversationTitleLabel?.textColor = UIColor.lightGray
            self.conversationInformationLabel?.text = nil
            self.unreadCountLabel?.text = nil
        }
    }

    /**
     * Layout subviews according to the conversation. Subclasses can override this method
     * to implement a custom layout.
     **/
    open func layoutSubviews(conversation: SKYConversation) {
        // title
        self.conversationTitleLabel?.textColor = self.conversationTitleLabel?.tintColor
        if let title = conversation.title {
            self.conversationTitleLabel?.text = title
        } else if let participantsTitle = self.conversation?.nameList(fromParticipants: self.participants) {
            self.conversationTitleLabel?.text = participantsTitle
        } else {
            self.conversationTitleLabel?.text = untitledConversation
            self.conversationTitleLabel?.textColor = UIColor.lightGray
        }

        // message
        if let message = self.conversationMessage {
            self.conversationMessageLabel.text = message
        } else {
            self.conversationMessageLabel.text = ""
        }

        // extra info
        if let info = self.conversationInformation {
            self.conversationInformationLabel?.text = info
        } else {
            let participantCount = conversation.participantIds.count
            let info: String
            if participantCount == 1 {
                info = NSLocalizedString("1 participant", comment: "")
            } else {
                info = String.localizedStringWithFormat("%d participants", participantCount)
            }

            self.conversationInformationLabel?.text = info
        }

        // unread count
        if let unreadCount = self.unreadMessageCount, unreadCount > 0 {
            self.unreadCountLabel?.text = String(unreadCount)
        } else {
            self.unreadCountView?.removeFromSuperview()
        }
    }
}
